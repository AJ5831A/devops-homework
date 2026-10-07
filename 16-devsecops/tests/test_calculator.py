import unittest
from app.calculator import calculate, response


class CalculatorTests(unittest.TestCase):
    def test_arithmetic(self):
        for operation, expected in [("add", 9), ("subtract", 3), ("multiply", 18), ("divide", 2)]:
            with self.subTest(operation=operation):
                self.assertEqual(calculate(operation, 6, 3), expected)

    def test_invalid_operands(self):
        for a, b in [("x", 1), ("nan", 1), (1, "inf"), ("-inf", 1)]:
            with self.subTest(a=a, b=b), self.assertRaises(ValueError):
                calculate("add", a, b)

    def test_overflow(self):
        with self.assertRaises(ValueError):
            calculate("multiply", 1e308, 1e308)

    def test_zero_division(self):
        with self.assertRaises(ValueError):
            calculate("divide", 1, 0)

    def test_unknown_operation(self):
        with self.assertRaises(ValueError):
            calculate("eval", 1, 2)

    def test_routes(self):
        self.assertEqual(response("/health"), (200, {"status": "ok"}))
        self.assertEqual(response("/calculate?op=add&a=2&b=3"), (200, {"result": 5.0}))
        self.assertEqual(response("/calculate?op=divide&a=2&b=0")[0], 400)
        self.assertEqual(response("/calculate?op=add")[0], 400)
        self.assertEqual(response("/missing")[0], 404)


if __name__ == "__main__":
    unittest.main()
