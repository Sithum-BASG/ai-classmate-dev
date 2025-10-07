export const REGION = 'asia-south1';

export interface DataPlatformConfig {
  dataProjectId: string;
  bigQueryDataset: string;
}

const defaultProject = process.env.DATA_PROJECT || process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'ai-classmate-dev';

export const DATA_PLATFORM: DataPlatformConfig = {
  dataProjectId: defaultProject,
  bigQueryDataset: process.env.BQ_DATASET || 'ai_classmate'
};

