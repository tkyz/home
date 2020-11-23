package jp.tkyz.core.debug;

import java.text.Format;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.TimeZone;

public final class StopWatch {

	private static final TimeZone GMT = TimeZone.getTimeZone("GMT");

	private static final Map<String, Format> CACHE = new HashMap<>();

	private long start = System.currentTimeMillis();

	private StopWatch() {
	}

	public static StopWatch start() {
		return new StopWatch();
	}

	public String stop() {
		return stop("HH:mm:ss.SSS");
	}

	public String stop(final String pattern) {

		String ret = null;

		synchronized (CACHE) {

			SimpleDateFormat fmt = (SimpleDateFormat)CACHE.get(pattern);

			if (null == fmt) {

				fmt = new SimpleDateFormat(pattern);
				fmt.setTimeZone(GMT);

				CACHE.put(pattern, fmt);

			}

			ret = fmt.format(new Date(millis()));

		}

		return ret;

	}

	private long millis() {
		return System.currentTimeMillis() - start;
	}

}
