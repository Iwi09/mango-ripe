import unittest
from unittest.mock import patch

import numpy as np

import main


class FixedModel:
    n_features_in_ = 54

    def __init__(self, label):
        self.label = label

    def predict(self, features):
        return [self.label]


class PredictionCorrectionTests(unittest.TestCase):
    def setUp(self):
        self.features = np.zeros((1, 54))

    def test_svm_unripe_is_corrected_when_naive_bayes_says_overripe(self):
        svm = FixedModel("UnRipe")
        naive_bayes = FixedModel("OverRipe")

        with patch.object(main, "naive_bayes", naive_bayes):
            result, result_model, correction = main.prediksi_dengan_koreksi(
                svm,
                self.features,
                "svm",
            )

        self.assertEqual(result, "OverRipe")
        self.assertIs(result_model, naive_bayes)
        self.assertEqual(correction, "naive_bayes")

    def test_svm_keeps_unripe_when_naive_bayes_does_not_say_overripe(self):
        svm = FixedModel("UnRipe")
        naive_bayes = FixedModel("Ripe")

        with patch.object(main, "naive_bayes", naive_bayes):
            result, result_model, correction = main.prediksi_dengan_koreksi(
                svm,
                self.features,
                "svm",
            )

        self.assertEqual(result, "UnRipe")
        self.assertIs(result_model, svm)
        self.assertIsNone(correction)

    def test_naive_bayes_selection_is_unchanged(self):
        selected_model = FixedModel("Ripe")
        naive_bayes = FixedModel("OverRipe")

        with patch.object(main, "naive_bayes", naive_bayes):
            result, result_model, correction = main.prediksi_dengan_koreksi(
                selected_model,
                self.features,
                "naive_bayes",
            )

        self.assertEqual(result, "Ripe")
        self.assertIs(result_model, selected_model)
        self.assertIsNone(correction)


if __name__ == "__main__":
    unittest.main()
