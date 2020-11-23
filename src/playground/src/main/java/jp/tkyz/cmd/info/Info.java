package jp.tkyz.cmd.info;

import java.util.Collection;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.core.Main;

public class Info implements Main {

	private static final Logger log = LoggerFactory.getLogger(Info.class);

	public static void main(String... args)
			throws Exception {
		Main.call(args);
	}

	@Override
	public Void call()
			throws Exception {

		log.info("info:");
		log.info("  name: {}", name());
		log.info("  args:");
		for (String key : args()) {
			log.info("    - {}", key);
		}
		log.info("  stacktrace:");
		for (StackTraceElement e : Thread.currentThread().getStackTrace()) {
			log.info("    - {}", e);
		}
		log.info("  env:");
		for (String key : sort(System.getenv().keySet())) {

			String val = System.getenv().get(key);

			if (!";".equals(val) && -1 < val.indexOf(";")) {

				log.info("    {}:", key);
				for (String item : val.split(";")) {
					log.info("      - {}", item);
				}

			} else {
				log.info("    {}: {}", key, val);
			}

		}
		log.info("  prop:");
		for (String key : sort(System.getProperties().stringPropertyNames())) {

			String val = (String)System.getProperties().get(key);

			if (!";".equals(val) && -1 < val.indexOf(";")) {

				log.info("    {}:", key);
				for (String item : val.split(";")) {
					log.info("      - {}", item);
				}

			} else {
				log.info("    {}: {}", key, val);
			}

		}

		return null;

	}

	private List<String> sort(Collection<String> org) {

		List<String> list = new LinkedList<>();
		list.addAll(org);

		Collections.sort(list);

		return list;

	}

}
