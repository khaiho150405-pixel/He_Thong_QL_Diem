from unittest import TestCase

from src.adapters.checkpoints import candidates, metadata


class CheckpointInventoryTest(TestCase):
    def test_newest_does_not_override_reported_validation_accuracy(self):
        items = [
            dict(file="crnn_num_dot4.pth", modified_ns=1, reported_accuracy_percent=99.4, reported_cer=0.002),
            dict(file="crnn_num_dot5.pth", modified_ns=2, reported_accuracy_percent=98.0, reported_cer=0.01),
        ]
        result = candidates(items)
        self.assertEqual(result["newest_local_copy"], "crnn_num_dot5.pth")
        self.assertEqual(result["numeric_highest_reported_accuracy"], "crnn_num_dot4.pth")
        self.assertFalse(result["ready_for_inference"])

    def test_no_metric_does_not_invent_best_model(self):
        self.assertIsNone(candidates([])["numeric_highest_reported_accuracy"])
        self.assertEqual(metadata({"cnn.weights": object()})["status"], "state-only")

    def test_invalid_metrics_are_not_ranked(self):
        for value in [float("nan"), float("inf"), -1, 101, True, "99"]:
            row = metadata({"model_state_dict": {}, "val_acc": value})
            self.assertIsNone(row["reported_accuracy_percent"])

    def test_only_allowlisted_metadata_is_exposed(self):
        row = metadata({"model_state_dict": {}, "val_acc": 99.1, "cau_hinh": {"private_path": "secret"}})
        self.assertEqual(row["reported_accuracy_percent"], 99.1)
        self.assertNotIn("cau_hinh", row)
