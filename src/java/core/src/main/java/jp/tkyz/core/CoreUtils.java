package jp.tkyz.core;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.Flushable;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.UnsupportedEncodingException;
import java.lang.management.ManagementFactory;
import java.lang.reflect.Array;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.net.ConnectException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.channels.SocketChannel;
import java.nio.channels.UnresolvedAddressException;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.sql.Connection;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import org.apache.commons.codec.net.URLCodec;
import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class CoreUtils {

	/** ロガー */
	private static final Logger log = LoggerFactory.getLogger(CoreUtils.class);

	public static final int CPU_CORE = Runtime.getRuntime().availableProcessors();

	public static final String PID = ManagementFactory.getRuntimeMXBean().getName().replaceAll("@.*", "");

	private CoreUtils() {
	}

	/**
	 * コンテナで動作しているかどうかを返します。
	 *
	 * @return true:コンテナで動作している場合、false:それ以外の場合
	 */
	public static boolean docker() {
		return new File("/.dockerenv").exists();
	}

	public static boolean empty(Object obj) {

		boolean empty = false;

		if (null == obj) {
			empty = true;

		} else if (obj instanceof Boolean) {
			empty = ((Boolean)obj).booleanValue();

		} else if (obj instanceof Character) {
			empty = 0 == ((Character)obj).charValue();

		} else if (obj instanceof Byte || obj instanceof Short || obj instanceof Integer || obj instanceof Long || obj instanceof AtomicInteger || obj instanceof AtomicLong) {
			empty = 0L == ((Number)obj).longValue();

		} else if (obj instanceof Float || obj instanceof Double) {
			empty = 0.0d == ((Number)obj).doubleValue();

		} else if (obj instanceof BigInteger) {
			empty = BigInteger.ZERO == obj;

		} else if (obj instanceof BigDecimal) {
			empty = BigDecimal.ZERO == obj;

		} else if (obj instanceof CharSequence) {
			empty = obj.toString().isBlank();

		} else if (obj.getClass().isArray()) {
			empty = 0 == Array.getLength(obj);

		} else if (obj instanceof Collection) {
			empty = ((Collection<?>)obj).isEmpty();

		} else if (obj instanceof Map) {
			empty = ((Map<?, ?>)obj).isEmpty();

		} else if (obj instanceof File) {

			File file = (File)obj;

			if (!Files.exists(file.toPath())) {
				empty = true;

			} else if (file.isFile()) {
				empty = 0 == file.length();

			} else if (file.isDirectory()) {
				empty = null == file.listFiles();
			}

		} else {
			throw new UnsupportedOperationException(obj.getClass().getName());
		}

		return empty;

	}

	/**
	 * 値を任意の型にキャストします。
	 *
	 * @param type キャストする型
	 * @param in 値
	 * @return キャストされた値
	 */
	@SuppressWarnings("unchecked")
	public static <I, O> O cast(final Class<O> type, final I in) {

		Object out = null;

		if (boolean.class == type || Boolean.class == type) {
			out = empty(in) ? Boolean.FALSE : Boolean.TRUE;

		} else if (char.class == type || Character.class == type) {
			throw new UnsupportedOperationException();

		} else if (byte.class == type || Byte.class == type) {

			String str = null == in ? null : in.toString().trim();

			out = empty(str) ? (type.isPrimitive() ? Byte.valueOf((byte)0) : null) : Byte.valueOf(str);

		} else if (short.class == type || Short.class == type) {

			String str = null == in ? null : in.toString().trim();

			out = empty(str) ? (type.isPrimitive() ? Short.valueOf((short)0) : null) : Short.valueOf(str);

		} else if (int.class == type || Integer.class == type) {

			String str = null == in ? null : in.toString().trim();

			out = empty(str) ? (type.isPrimitive() ? Integer.valueOf(0) : null) : Integer.valueOf(str);

		} else if (long.class == type || Long.class == type) {

			String str = null == in ? null : in.toString().trim();

			out = empty(str) ? (type.isPrimitive() ? Long.valueOf(0L) : null) : Long.valueOf(str);

		} else if (float.class == type || Float.class == type) {

			String str = null == in ? null : in.toString().trim();

			out = empty(str) ? (type.isPrimitive() ? Float.valueOf(0.0f) : null) : Float.valueOf(str);

		} else if (double.class == type || Double.class == type) {

			String str = null == in ? null : in.toString().trim();

			out = empty(str) ? (type.isPrimitive() ? Double.valueOf(0.0d) : null) : Double.valueOf(str);

		} else if (null == in || in.getClass() == type) {
			out = in;

		} else if (BigInteger.class == type) {
			out = new BigInteger(in.toString().trim());

		} else if (BigDecimal.class == type) {
			out = new BigDecimal(in.toString().trim());

		} else if (String.class == type) {
			out = in.toString();

		} else {
			throw new UnsupportedOperationException();
		}

		return (O)out;

	}

	/**
	 * <pre>
	 * ２つのオブジェクトが等価かどうかを返します。
	 * 等価の判定は基本的には{@link Object#equals(Object)}が使用されますが、プリミティブ型のラッパークラスの場合は実際の値で比較されます。
	 * </pre>
	 *
	 * @param o1 オブジェクト1
	 * @param o2 オブジェクト2
	 * @return true:２つのオブジェクトが等価の場合、false:それ以外の場合
	 */
	public static boolean equals(Object o1, Object o2) {

		Deque<Object> q1 = new ArrayDeque<>();
		Deque<Object> q2 = new ArrayDeque<>();

		q1.add(o1);
		q2.add(o2);

		int depth = 1;

		boolean equals = true;
		while (!empty(q1) || !empty(q2)) {

			Object v1 = q1.remove();
			Object v2 = q2.remove();

			// インスタンスで比較
			if (v1 == v2) {
				continue;
			}
			if (null == v1 && null != v2) {
				equals = false;
				break;
			}
			if (null != v1 && null == v2) {
				equals = false;
				break;
			}

			// long値で比較
			{

				boolean chk = false;
				chk |= v1 instanceof Byte || v1 instanceof Short || v1 instanceof Integer || v1 instanceof Long || v1 instanceof AtomicInteger || v1 instanceof AtomicLong;
				chk |= v2 instanceof Byte || v2 instanceof Short || v2 instanceof Integer || v2 instanceof Long || v2 instanceof AtomicInteger || v2 instanceof AtomicLong;

				if (chk && ((Number)v1).longValue() == ((Number)v2).longValue()) {
					continue;
				}

			}

			// double値で比較
			{

				boolean chk = false;
				chk |= v1 instanceof Float || v1 instanceof Double;
				chk |= v2 instanceof Float || v2 instanceof Double;

				if (chk && ((Number)v1).doubleValue() == ((Number)v2).doubleValue()) {
					continue;
				}

			}

			// 配列の場合
			if (v1.getClass().isArray() && v2.getClass().isArray() && 0 < depth--) {

				int l1 = Array.getLength(v1);
				int l2 = Array.getLength(v2);

				if (l1 != l2) {
					equals = false;
					break;
				}

				for (int i = 0; i < l1; i++) {
					q1.add(Array.get(v1, i));
					q2.add(Array.get(v2, i));
				}

				continue;

			}

			// コレクションの場合
			if (v1 instanceof Collection && v2 instanceof Collection && 0 < depth--) {

				Collection<?> c1 = (Collection<?>)v1;
				Collection<?> c2 = (Collection<?>)v1;

				if (c1.size() != c2.size()) {
					equals = false;
					break;
				}

				c1.forEach(q1::add);
				c2.forEach(q2::add);

				continue;

			}

			// マップの場合
			if (v1 instanceof Map && v2 instanceof Map && 0 < depth--) {

				Map<?, ?> m1 = (Map<?, ?>)v1;
				Map<?, ?> m2 = (Map<?, ?>)v2;

				if (m1.size() != m2.size()) {
					equals = false;
					break;
				}

				m1.keySet().forEach(q1::add);
				m2.keySet().forEach(q2::add);

				m1.values().forEach(q1::add);
				m2.values().forEach(q2::add);

				continue;

			}

			if (v1.hashCode() != v2.hashCode()) {
				equals = false;
				break;
			}
			if (!v1.equals(v2)) {
				equals = false;
				break;
			}

		}

		return equals;

	}

	/**
	 * 最初に現れるnullではない値を返します。
	 *
	 * @param v 値
	 * @return 最初に現れるnullではない値
	 */
	@SuppressWarnings("unchecked")
	public static <T> T nvl(T... v) {
		return nvl(List.of(v));
	}

	/**
	 * 最初に現れるnullではない値を返します。
	 *
	 * @param v 値
	 * @return 最初に現れるnullではない値
	 */
	public static <T> T nvl(Collection<T> v) {

		T ret = null;

		for (T t : v) {

			if (empty(t)) {
				continue;
			}

			ret = t;

			break;

		}

		return ret;

	}

	public static List<String> lines(String text) {
		return new ArrayList<>(List.of(text.split("[\r\n]+")));
	}

	/**
	 * キャメルケース文字列をスネークケース文字列に変換します。
	 *
	 * @param camel キャメルケース文字列
	 * @return 変換後の文字列
	 */
	public static String snake(CharSequence camel) {

		StringBuilder ret = new StringBuilder();

		for (int i = 0; i < camel.length(); i++) {

			char c = camel.charAt(i);

			if (Character.isUpperCase(c) && 0 < ret.length()) {
				ret.append('_');
			}

			ret.append(Character.toLowerCase(c));

		}

		return ret.toString();

	}

	/**
	 * スネークケース文字列をキャメルケース文字列に変換します。
	 *
	 * @param snake スネークケース文字列
	 * @return 変換後の文字列
	 */
	public static String camel(CharSequence snake) {

		StringBuilder ret = new StringBuilder();

		boolean upper = false;
		for (int i = 0; i < snake.length(); i++) {

			char c = snake.charAt(i);
			if ('_' == c) {

				upper = true;

			} else if (upper) {

				ret.append(Character.toUpperCase(c));

				upper = false;

			} else {
				ret.append(Character.toLowerCase(c));
			}

		}

		return ret.toString();

	}

	public static String join(CharSequence delim, CharSequence value, int count) {

		StringBuilder join = new StringBuilder();

		for (int i = 0; i < count; i++) {
			join.append(0 == i ? "" : delim);
			join.append(value);
		}

		return join.toString();

	}

	public static void open(String host, int port, long timeout)
			throws IOException, InterruptedException {

		timeout += System.currentTimeMillis();
		while (true) {

			try (SocketChannel sock = SocketChannel.open(new InetSocketAddress(host, port))) {
				break;

			} catch (UnresolvedAddressException | ConnectException e) {

				if (timeout <= System.currentTimeMillis()) {
					throw new IOException("open timeout. [host=" + host + ", port=" + port + "]", e);
				}

				Thread.sleep(1000);
				continue;

			}

		}

	}

	public static byte[] read(String path)
			throws IOException {

		byte[] bytes = null;

		// 作業ディレクトリ
		if (empty(bytes)) {

			File file = new File(path);
			if (file.isFile()) {

				bytes = Files.readAllBytes(file.toPath());

				log.debug("read. [file://{}]", path);

			}

		}

		// クラスパス
		if (empty(bytes)) {

			try (InputStream in = CoreUtils.class.getClassLoader().getResourceAsStream(path)) {
				if (null != in) {

					bytes = read(in);

					log.debug("read. [classpath://{}]", path);

				}
			}

		}

		if (empty(bytes)) {
			throw new FileNotFoundException(path);
		}

		return bytes;

	}

	public static byte[] read(InputStream in)
			throws IOException {

		byte[] bytes = null;

		try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {

			pipe(out, in);

			bytes = out.toByteArray();

		} finally {
			close(in);
		}

		return bytes;

	}

	/**
	 * フラッシュします。
	 *
	 * @param flushables フラッシュ可能オブジェクト
	 */
	public static void flush(Flushable... flushables) {

		for (Flushable flushable : flushables) {

			if (null != flushable) {

				try {

					flushable.flush();

				} catch (IOException e) {
					log.warn("flush failed.", e);
				}

			}

		}

	}

	/**
	 * クローズします。
	 *
	 * @param closeables クローズ可能オブジェクト
	 */
	public static void close(AutoCloseable... closeables) {

		for (AutoCloseable closeable : closeables) {

			if (null != closeable) {

				// コネクションの場合はロールバックもしておく
				if (closeable instanceof Connection) {

					try {

						if (!((Connection)closeable).getAutoCommit()) {
							((Connection)closeable).rollback();
						}

					} catch (SQLException e) {
						log.warn("close failed.", e);
					}

				}

				try {

					closeable.close();

				} catch (Exception e) {
					log.warn("close failed.", e);
				}

			}

		}

	}

	public static void lock(Class<?> clazz)
			throws IOException {

		File file = new File("/run/lock/", clazz.getName() + ".lock");
		file.deleteOnExit();

		FileChannel channel = FileChannel.open(file.toPath(), StandardOpenOption.CREATE, StandardOpenOption.WRITE);

		FileLock lock = channel.tryLock();
		if (null == lock) {
			throw new IOException("lock failed. [file=" + file + "]");
		}

		// シャットダウンフックに追加
		Runtime.getRuntime().addShutdownHook(new Thread(() -> {
			close(lock, channel);
		}));

	}

	public static StackTraceElement current() {
		return Thread.currentThread().getStackTrace()[2];
	}

	public static StackTraceElement caller() {
		return Thread.currentThread().getStackTrace()[3];
	}

	public static String now(String pattern) {

		SimpleDateFormat df = new SimpleDateFormat(pattern);

		return df.format(new Date());

	}

	/**
	 * 入力ストリームから出力ストリームへデータを流し込みます。
	 *
	 * @param in 入力ストリーム
	 * @param out 出力ストリーム
	 * @throws IOException 例外
	 */
	public static void pipe(OutputStream out, InputStream in)
			throws IOException {

		byte[] buffer = new byte[1 << 16];
		int readsize = -1;

		while (-1 < (readsize = in.read(buffer))) {
			out.write(buffer, 0, readsize);
			flush(out);
		}

	}

	public static <T> Class<T> findClass(String pkg) {

//		Class<T> clazz = null;
//
//		return clazz;

		throw new UnsupportedOperationException();

	}

	public static <T> Class<T> findClass(Package pkg) {
		return findClass(pkg.getName());
	}

	public static String ping(URI uri)
			throws IOException {

		InetAddress[] addr = InetAddress.getAllByName(uri.getHost());

		if (1 != addr.length) {
			throw new IOException(uri.getHost());
		}

		return addr[0].getHostAddress();

	}

	/**
	 * スタックトレースを文字列として返します。
	 *
	 * @param t スロー
	 * @return スタックトレースの文字列
	 */
	public static String stackTrace(Throwable t) {

		String val = null;

		try (StringWriter sw = new StringWriter(); PrintWriter pw = new PrintWriter(sw)) {

			t.printStackTrace(pw);
			flush(pw);

			val = sw.toString();

		} catch (IOException e) {
			log.warn("", e);
		}

		return val;

	}

	public static void delete(File target)
			throws IOException {

		if (!empty(target)) {

			if (target.isFile()) {
				target.delete();

			} else {
				FileUtils.deleteDirectory(target);
			}

		}

	}

	public static URI resolve(URI base, String child, String charset)
			throws URISyntaxException, UnsupportedEncodingException {

		if (child.matches("^[^/]*//[^/]+$")) {
			child += "/";
		}

		URI uri = null;
		if (null == base) {
			uri = new URI(child);

		} else if (child.startsWith("//")) {
			uri = base.resolve(new URI(child));

		} else if (child.endsWith("/")) {
			uri = base.resolve(new URI(child));

		} else {

			int sep = child.lastIndexOf("/");

			if (-1 == sep) {
				uri = base.resolve(new URI(child));

			} else {

				uri = base.resolve(new URI(child.substring(0, sep + 1)));

				child = child.substring(sep + 1);
				if (child.length() != child.getBytes().length) {
					child = new URLCodec().encode(child, charset);
				}

				uri = uri.resolve(new URI(child));

			}

		}

		return uri.normalize();

	}

	public static File file(String parent, String... childs) {
		return file(new File(parent), childs);
	}

	public static File file(File parent, String... childs) {

		File file = parent;

		for (String child : childs) {
			file = new File(file, child);
		}

		return file;

	}

}
