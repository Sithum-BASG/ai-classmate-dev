export const REGION = 'asia-south1';

export interface DataPlatformConfig {
  dataProjectId: string;
  bigQueryDataset: string;
}

export const DATA_PLATFORM: DataPlatformConfig = {
  dataProjectId: process.env.DATA_PROJECT || 'ai-classmate-sri-lanka-001',
  bigQueryDataset: process.env.BQ_DATASET || 'ai_classmate'
};

