package jp.tkyz;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.Main;
import jp.tkyz.core.reflect.UnimplementedException;

public class Playground implements Main {

	private static final Logger log = LoggerFactory.getLogger(Playground.class);

	public static void main(String... args)
			throws Exception {
		Main.call(args);
	}

	@Override
	public Void call()
			throws Exception {

		if (CoreUtils.empty(args())) {
			main();

		} else {
			cmd(args().remove(0));
		}

		return null;

	}

	private void main()
			throws Exception {

		log.info("cmd:");
		cmds(getClass().getPackageName() + ".cmd", 1).forEach(e -> log.info("  - {}", e.getPackageName().replaceAll(".*\\.", "").replace("_", "-")));

	}

	private <T extends Main> void cmd(final String name)
			throws Exception {

		String pkg = getClass().getPackage().getName() + ".cmd." + name.replace("-", "_");

		List<Class<T>> classes = cmds(pkg, 0);
		if (1 != classes.size()) {
			throw new UnsupportedOperationException();
		}

		Class<T> clazz = classes.get(0);

		log.trace("cmd [class={}, args={}]", clazz.getName(), args());

		Main.of(clazz, args()).call();

	}

	@SuppressWarnings("unchecked")
	private <T extends Main> List<Class<T>> cmds(final String pkg, final int depth)
			throws IOException {

		List<Class<T>> cmds = new ArrayList<>();

		URL url = Thread.currentThread().getContextClassLoader().getResource(pkg.replace(".", "/"));
		if ("file".equals(url.getProtocol())) {

			// ディレクトリ検索
			List<File> dirs = new ArrayList<>();
			{

				File dir = new File(URLDecoder.decode(url.getFile(), "utf8"));

				List<File> queue = new ArrayList<>();
				queue.add(dir);

				for (int i = 0; i < depth; i++) {

					List<File> work = new ArrayList<>(); 

					for (File item : queue) {

						File[] childs = item.listFiles(f -> f.isDirectory());

						if (CoreUtils.empty(childs)) {
							continue;
						}

						work.addAll(Arrays.asList(childs));

					}

					queue.clear();
					queue.addAll(work);

				}

				dirs.addAll(queue);

			}

			// クラス検索
			for (File dir : dirs) {

				List<File> classes = new ArrayList<>();
				{

					File[] childs = dir.listFiles(f -> f.isFile() && f.getName().endsWith(".class"));
					if (!CoreUtils.empty(childs)) {
						classes.addAll(Arrays.asList(childs));
					}

				}

				int idx = -1;
				for (File file : classes) {

					String path = file.getCanonicalPath().replace("\\", ".");
					if (-1 == idx) {
						idx = path.lastIndexOf(getClass().getPackage().getName());
					}

					String className = path.substring(idx).replaceAll(".class$", "");

					Class<?> clazz = null;
					try {
						clazz = Class.forName(className);
					} catch (ClassNotFoundException e) {
						continue;
					}

					if (!Main.class.isAssignableFrom(clazz)) {
						continue;
					}

					cmds.add((Class<T>)clazz);

				}

			}

		} else if ("jar".equals(url.getProtocol())) {
			throw new UnimplementedException();
		}

		return cmds;

	}

}
