package jp.tkyz.cmd.git_commit_hash;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.concurrent.atomic.AtomicLong;

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.codec.digest.MessageDigestAlgorithms;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.Main;
import jp.tkyz.core.concurrent.IoWorker;

public class GitCommitHash implements Main {

	private static final Logger log = LoggerFactory.getLogger(GitCommitHash.class);

	private static boolean branch = false;

	private static String username = "tkyz";
	private static String email    = "36824716+tkyz@users.noreply.github.com";
	private static String timezone = "+0900";
	private static String comment  = "first commit";

	private static AtomicLong date = null;

	private static long   adopt_sec  = -1;
	private static String adopt_hash = null;

	private static final String lf = "\n";
	private static final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

	public static void main(String... args)
			throws Exception {
		Main.call(args);
	}

	@Override
	public Void call()
			throws Exception {

		if (!branch) {
			branch = true;
			main();

		} else {
			worker();
		}

		return null;

	}

	private void main()
			throws Exception {

		date = new AtomicLong(System.currentTimeMillis() / 1000);
//		date = new AtomicLong(1335027608L);

		for (int i = 0; i < CoreUtils.CPU_CORE; i++) {
			IoWorker.add(Main.of(GitCommitHash.class));
		}

	}

	private void worker()
			throws Exception {

		long sec = -1;
		while (-1 < (sec = date.getAndDecrement())) {

			StringBuilder object = new StringBuilder();
			object.append("tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904" + lf);
			object.append("author " + username + " <" + email + "> " + sec + " " + timezone + lf);
			object.append("committer " + username + " <" + email + "> " + sec + " " + timezone + lf);
			object.append(lf);
			object.append(comment + lf);

			String in = "commit " + object.length() + "\0" + object;

			String hash = new DigestUtils(MessageDigestAlgorithms.SHA_1).digestAsHex(in);

			boolean adopt = false;
			if (CoreUtils.empty(adopt_hash) || hash.compareTo(adopt_hash) < 0) {
				adopt = adopt(sec, hash);
			}

			if (adopt || 0 == sec % 1000000) {

				String cur_date = df.format(new Date(1000 * sec));
				String adp_date = df.format(new Date(1000 * adopt_sec));

				log.info("current=[sec=" + sec + ", date=" + cur_date + "], adopt=[sec=" + adopt_sec + ", date=" + adp_date + ", hash=" + adopt_hash + "]");

			}

		}
//		if (-1 < sec) {
//			IoWorker.add(Main.of(GitCommitHash.class));
//		}

	}

	private synchronized boolean adopt(long sec, String hash) {

		boolean update = false;

		if (CoreUtils.empty(adopt_hash) || hash.compareTo(adopt_hash) < 0) {

			adopt_sec  = sec;
			adopt_hash = hash;

			update = true;

		}

		return update;

	}

}
