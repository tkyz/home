package jp.tkyz.core.concurrent;

import java.util.Deque;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentLinkedDeque;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.debug.StopWatch;

public final class IoWorker {

	private static final Logger log = LoggerFactory.getLogger(IoWorker.class);

	private static final ExecutorService executor = Executors.newFixedThreadPool(CoreUtils.CPU_CORE, new ThreadFactory() {

		private AtomicInteger counter = new AtomicInteger();

		@Override
		public Thread newThread(Runnable r) {
			return new Thread(r, "io-worker-" + counter.incrementAndGet());
		}

	});

	private static final Deque<Future<?>> futures = new ConcurrentLinkedDeque<>();

	public static <T> Future<T> add(final Runnable runnable) {
 
		return add(() -> {

			runnable.run();

			return null;

		});

	}

	public static <T> Future<T> add(final Callable<T> callable) {

		Future<T> future = executor.submit(() -> {

			StopWatch sw = null;
			if (log.isTraceEnabled()) {
				sw = StopWatch.start();
				log.trace("START");
			}

			T ret = callable.call();

			if (log.isTraceEnabled()) {
				log.trace("END [time={}]", sw.stop());
			}

			return ret;

		});

		futures.addLast(future);

		return future;

	}

	public static void join()
			throws ExecutionException, InterruptedException {

		while (!CoreUtils.empty(futures)) {

			Future<?> future = futures.removeFirst();

			if (!future.isDone()) {

				futures.addLast(future);

				Thread.yield();

				continue;

			}

			try {

				future.get();

			} catch (InterruptedException e) {

				if (!future.isCancelled()) {
					throw e;
				}

			} catch (ExecutionException e) {
				throw e;
			}

		}

	}

	public static void shutdown(final boolean force) {

		if (force) {
			executor.shutdownNow();

		} else {
			executor.shutdown();
		}

	}

}
