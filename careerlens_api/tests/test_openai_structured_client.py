import unittest

from app.services.openai_structured_client import OpenAIStructuredClient


class OpenAIStructuredClientTests(unittest.TestCase):
    def test_extract_output_json_prefers_output_parsed(self):
        response_json = {"output_parsed": {"headline": "Software Engineer"}}

        result = OpenAIStructuredClient.extract_output_json(response_json)

        self.assertEqual(result, {"headline": "Software Engineer"})

    def test_extract_output_json_reads_parsed_content(self):
        response_json = {
            "output": [
                {
                    "content": [
                        {
                            "parsed": {"headline": "Data Analyst"},
                        }
                    ]
                }
            ]
        }

        result = OpenAIStructuredClient.extract_output_json(response_json)

        self.assertEqual(result, {"headline": "Data Analyst"})

    def test_extract_output_json_reads_json_text_content(self):
        response_json = {
            "output": [
                {
                    "content": [
                        {
                            "text": '{"headline": "Backend Developer"}',
                        }
                    ]
                }
            ]
        }

        result = OpenAIStructuredClient.extract_output_json(response_json)

        self.assertEqual(result, {"headline": "Backend Developer"})

    def test_extract_output_json_raises_when_payload_is_missing(self):
        with self.assertRaisesRegex(ValueError, "structured JSON output"):
            OpenAIStructuredClient.extract_output_json({"output": []})
