import type {
  OfflineQueueJob,
  OfflineQueueRepository,
} from "./offline-queue.types";

export class MemoryOfflineQueueRepository implements OfflineQueueRepository {
  private readonly jobs = new Map<string, OfflineQueueJob<unknown>>();

  async enqueue<TPayload>(job: OfflineQueueJob<TPayload>): Promise<void> {
    this.jobs.set(job.id, job as OfflineQueueJob<unknown>);
  }

  async listPending(limit = 50): Promise<Array<OfflineQueueJob<unknown>>> {
    return [...this.jobs.values()]
      .filter((job) => job.status === "PENDING" || job.status === "FAILED")
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt))
      .slice(0, limit);
  }

  async markProcessing(jobId: string): Promise<void> {
    this.patchJob(jobId, {
      status: "PROCESSING",
      updatedAt: new Date().toISOString(),
    });
  }

  async markCompleted(jobId: string): Promise<void> {
    this.patchJob(jobId, {
      status: "COMPLETED",
      updatedAt: new Date().toISOString(),
    });
  }

  async markFailed(jobId: string, errorMessage: string): Promise<void> {
    const current = this.getJob(jobId);

    this.patchJob(jobId, {
      status: "FAILED",
      retryCount: current.retryCount + 1,
      lastError: errorMessage,
      updatedAt: new Date().toISOString(),
    });
  }

  private getJob(jobId: string): OfflineQueueJob<unknown> {
    const job = this.jobs.get(jobId);

    if (!job) {
      throw new Error(`Offline queue job not found: ${jobId}.`);
    }

    return job;
  }

  private patchJob(
    jobId: string,
    patch: Partial<OfflineQueueJob<unknown>>,
  ): void {
    const current = this.getJob(jobId);

    this.jobs.set(jobId, {
      ...current,
      ...patch,
    });
  }
}
