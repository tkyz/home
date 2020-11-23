package jp.tkyz.cmd.cleaner;

import java.io.File;
import java.io.IOException;
import java.util.List;

import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.Main;

public class Cleaner implements Main {

	public static void main(String... args)
			throws Exception {
		Main.call(args);
	}

	@Override
	public Void call()
			throws IOException {

		List<String> args = args();
		for (String arg : args) {
			clean(new File(arg));
		}

		return null;

	}

	/**
	 * <pre>
	 * 以下のファィルまたはディレクトリを再帰的に削除します。
	 *   - サイズが0バイトのファイル
	 *   - 中身が空のディレクトリ
	 * </pre>
	 *
	 * @param target 対象
	 * @return
	 */
	private boolean clean(File target)
			throws IOException {

		boolean delete = true;

		if (target.isDirectory()) {

			File[] childs = target.listFiles();
			if (!CoreUtils.empty(childs)) {
				for (File child : childs) {
					delete &= clean(child);
				}
			}

		} else if (target.isFile()) {
			delete &= 0 == target.length();

		} else {
			delete = false;
		}

		if (delete) {
			CoreUtils.delete(target);
		}

		return delete;

	}

}
