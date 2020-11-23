package jp.tkyz.core;

import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.Callable;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javassist.util.proxy.ProxyFactory;
import jp.tkyz.core.concurrent.IoWorker;
import jp.tkyz.core.debug.StopWatch;
import jp.tkyz.core.reflect.UnimplementedException;

public interface Main extends Callable<Void> {

	public default String name() {
		throw new UnimplementedException();
	}

	public default List<String> args() {
		throw new UnimplementedException();
	}

	public static <T extends Main> T of(final Class<T> type, final String... args)
			throws ReflectiveOperationException {
		return of(type, new LinkedList<>(List.of(args)));
	}

	public static <T extends Main> T of(final Class<T> type, final List<String> args)
			throws ReflectiveOperationException {

		ProxyFactory factory = new ProxyFactory();
		factory.setSuperclass(type);
		factory.setFilter(method -> Main.class == method.getDeclaringClass() && method.isDefault());

		@SuppressWarnings("unchecked")
		T proxy = (T)factory.create(null, null, (self, method, proceed, params) -> {

			Object ret = null;

			if (Main.class.getDeclaredMethod("name").equals(method)) {
				ret = type.getName();

			} else if (Main.class.getDeclaredMethod("args").equals(method)) {
				ret = args;

			} else {
				throw new UnimplementedException();
			}

			return ret;

		});

		return proxy;

	}

	public static <T extends Main> void call(final String... args)
			throws Exception {

		StackTraceElement[] stack = Thread.currentThread().getStackTrace();

		StackTraceElement first = stack[stack.length - 1];

		// mainからのみ許可
		{

			boolean main = true;
			main &= 1 == Thread.currentThread().getId();
			main &= 3 == stack.length;
			main &= "main".equals(first.getMethodName());

			if (!main) {
				throw new IllegalStateException();
			}

		}

		Logger log = LoggerFactory.getLogger(Main.class);
		try {

			@SuppressWarnings("unchecked")
			Class<T> type = (Class<T>)Class.forName(first.getClassName());

			StopWatch sw = null;
			if (log.isTraceEnabled()) {
				sw = StopWatch.start();
				log.trace("START [class={}, args={}]", type.getName(), args);
			}

			IoWorker.add(of(type, args));
			IoWorker.join();

			if (log.isTraceEnabled()) {
				log.trace("END [time={}]", sw.stop());
			}

		} finally {
			IoWorker.shutdown(false);
		}

	}

}
