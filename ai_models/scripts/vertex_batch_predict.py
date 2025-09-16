import argparse
from google.cloud import aiplatform


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--project", required=True)
	parser.add_argument("--location", default="asia-south1")
	parser.add_argument("--model_id", required=True)
	parser.add_argument("--bq_source", default="ai-classmate-sri-lanka-001.ai_classmate.recs_scoring_input")
	parser.add_argument("--bq_destination_prefix", default="ai-classmate-sri-lanka-001.ai_classmate")
	args = parser.parse_args()

	aiplatform.init(project=args.project, location=args.location)
	model = aiplatform.Model(model_name=f"projects/{args.project}/locations/{args.location}/models/{args.model_id}")

	job = model.batch_predict(
		bigquery_source=f"bq://{args.bq_source}",
		bigquery_destination_prefix=f"bq://{args.bq_destination_prefix}",
		sync=False,
	)
	print(f"Batch prediction started: {job.resource_name}")


if __name__ == "__main__":
	main()
