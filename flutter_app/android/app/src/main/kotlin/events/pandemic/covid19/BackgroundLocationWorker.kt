package events.pandemic.covid19

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class BackgroundLocationWorker(appContext: Context, workerParams: WorkerParameters) :
        Worker(appContext, workerParams) {

    override fun doWork(): Result {
        return Result.success();
    }
}