#!/usr/bin/env python3
"""Offline structural checks. Requires PyYAML; not a Kubernetes API validator."""
import ast
import json
from pathlib import Path
import re
import subprocess
import sys
import yaml

ROOT = Path(__file__).resolve().parents[1]
errors = []
counts = {'yaml': 0, 'json': 0, 'python': 0, 'shell': 0, 'links': 0}
for path in sorted(ROOT.rglob('*')):
    if not path.is_file() or any(p in {'.git', '__pycache__', '.venv', '.terraform'} for p in path.parts):
        continue
    try:
        if path.suffix in {'.yaml', '.yml'} and 'templates' not in path.parts:
            # BaseLoader preserves GitHub Actions' `on` instead of YAML 1.1 boolean coercion.
            documents = list(yaml.load_all(path.read_text(), Loader=yaml.BaseLoader))
            counts['yaml'] += 1
            for obj in documents:
                if not isinstance(obj, dict):
                    continue
                if path.parent.name == 'workflows':
                    assert 'on' in obj and 'jobs' in obj, 'workflow missing triggers/jobs'
                    for job in obj['jobs'].values():
                        dependencies = job.get('needs', [])
                        if isinstance(dependencies, str): dependencies = [dependencies]
                        assert all(d in obj['jobs'] for d in dependencies), 'unknown job dependency'
                if 'kind' in obj:
                    assert obj.get('apiVersion') and obj.get('metadata', {}).get('name'), 'resource identity missing'
                if obj.get('kind') in {'Deployment', 'ReplicaSet'}:
                    selector = obj['spec']['selector']['matchLabels']
                    labels = obj['spec']['template']['metadata']['labels']
                    assert all(labels.get(k) == v for k, v in selector.items()), 'selector/template mismatch'
                    pod = obj['spec']['template']['spec']
                elif obj.get('kind') == 'Pod':
                    pod = obj['spec']
                else:
                    continue
                volumes = {v['name'] for v in pod.get('volumes', [])}
                for container in pod.get('containers', []) + pod.get('initContainers', []):
                    assert container.get('image'), 'container missing image'
                    assert all(v['name'] in volumes for v in container.get('volumeMounts', [])), 'missing mounted volume'
        elif path.suffix == '.json':
            json.loads(path.read_text()); counts['json'] += 1
        elif path.suffix == '.py':
            ast.parse(path.read_text()); counts['python'] += 1
        elif path.suffix == '.sh':
            result = subprocess.run(['bash', '-n', str(path)], capture_output=True, text=True)
            assert result.returncode == 0, result.stderr
            counts['shell'] += 1
        elif path.suffix == '.md':
            text = re.sub(r'```.*?```', '', path.read_text(), flags=re.S)
            for target in re.findall(r'\]\(([^\s)]+)(?:\s+"[^"]*")?\)', text):
                if '://' in target or target.startswith(('#', 'mailto:')):
                    continue
                target = target.split('#')[0]
                if target:
                    assert (path.parent / target).exists(), 'broken link: ' + target
                    counts['links'] += 1
    except Exception as exc:
        errors.append(f'{path.relative_to(ROOT)}: {exc}')

canonical = ROOT / '.github/workflows/final-project.yml'
copy = ROOT / 'final-devops-project/.github/workflows/final-project.yml'
if canonical.read_bytes() != copy.read_bytes():
    errors.append('Final workflow copy differs from canonical root workflow')
print('Offline structural checks:', ', '.join(f'{n} {k}' for k,n in counts.items()))
if errors:
    print('\n'.join(errors)); sys.exit(1)
print('PASS. Helm rendering, Terraform validation and runtime behavior require separate tooling.')
