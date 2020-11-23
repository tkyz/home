package jp.tkyz.core.model;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Serializable;
import java.lang.invoke.MethodHandles.Lookup;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.nio.file.Files;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Objects;
import java.util.Properties;

import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;

import org.apache.commons.lang3.SerializationUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.Tkyz;
import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.reflect.Proxy;

/**
 * 汎用的なエンティティクラスです。
 */
public interface Entity extends Serializable {

	/**
	 * このエンティティに引数で指定されたマップをマッピングします。
	 *
	 * @param map マップ
	 */
	public void map(final Map<? extends Object, ? extends Object> map);

	/**
	 * このエンティティに引数で指定された結果セットをマッピングします。
	 *
	 * @param rs 結果セット
	 * @throws SQLException 例外
	 */
	public void map(final ResultSet rs)
			throws SQLException;

	public void map(final File file)
			throws IOException;

	public Map<String, Serializable> map();

	/**
	 * 新しいエンティティのインスタンスを作成します。
	 *
	 * @param type 作成するエンティティの型
	 * @return 作成されたエンティティのインスタンス
	 */
	public static <T extends Entity> T of(final Class<T> type) {

		Logger log = LoggerFactory.getLogger(type);

		// getterとして定義されているキーを保持
		Map<String, Serializable> entity = new HashMap<>();
		for (Method method : type.getMethods()) {

			boolean ignore = false;
			ignore |= method.isDefault();
			ignore |= Modifier.isStatic(method.getModifiers());
			ignore |= method.getDeclaringClass().isAssignableFrom(Entity.class);
			ignore |= 0 != method.getParameterCount();
			ignore |= void.class == method.getReturnType();
			ignore |= Void.class == method.getReturnType();
			if (ignore) {
				continue;
			}

			entity.put(method.getName(), null);

		}

		return (T)Proxy.of(type, new InvocationHandler() {

			@Override
			@SuppressWarnings("unchecked")
			public Object invoke(Object proxy, Method method, Object[] args)
					throws Throwable {

				Object ret = null;

				if (Object.class.getDeclaredMethod("hashCode").equals(method)) {
					ret = Integer.valueOf(Objects.hash(entity));

				} else if (Object.class.getDeclaredMethod("equals", Object.class).equals(method)) {
					ret = Boolean.valueOf(entity.equals(args[0]));

				} else if (Object.class.getDeclaredMethod("toString").equals(method)) {
					ret = entity.toString();

				} else if (method.isDefault()) {
					ret = def(proxy, method, args);

				} else if (Entity.class.getDeclaredMethod("map", Map.class).equals(method)) {
					map(proxy, method, (Map<? extends Object, ? extends Object>)args[0]);

				} else if (Entity.class.getDeclaredMethod("map", ResultSet.class).equals(method)) {
					map(proxy, method, (ResultSet)args[0]);

				} else if (Entity.class.getDeclaredMethod("map", File.class).equals(method)) {
					map(proxy, method, (File)args[0]);

				} else if (Entity.class.getDeclaredMethod("map").equals(method)) {
					ret = Collections.unmodifiableMap(entity);

				} else if (1 == method.getParameterCount() && (void.class == method.getReturnType() || Void.class == method.getReturnType())) {
					set(method.getName(), (Serializable)args[0]);

				} else if (0 == method.getParameterCount() && void.class != method.getReturnType() && Void.class != method.getReturnType()) {
					ret = get(method.getName());

				} else {
					throw new UnsupportedOperationException(method.toString());
				}

				return ret;

			}

			private Object def(Object proxy, Method method, Object[] args)
					throws Throwable {

				int modes = 0;
				modes |= Lookup.PUBLIC;
				modes |= Lookup.PRIVATE;
				modes |= Lookup.PROTECTED;
				modes |= Lookup.PACKAGE;

				Class<?> declaringClass = method.getDeclaringClass();

				Constructor<Lookup> constructor = Lookup.class.getDeclaredConstructor(Class.class, int.class);
				constructor.setAccessible(true);

				return constructor.newInstance(declaringClass, modes)
						.unreflectSpecial(method, declaringClass)
						.bindTo(proxy)
						.invokeWithArguments(args);

//				return MethodHandles.lookup()
//						.in(declaringClass)
//						.unreflectSpecial(method, declaringClass)
//						.bindTo(proxy)
//						.invokeWithArguments(args);

			}

			private void map(Object proxy, Method method, Map<? extends Object, ? extends Object> map) {

				for (Entry<? extends Object, ? extends Object> entry : map.entrySet()) {

					// 定義されていないキーは無視
					String key = entry.getKey().toString();
					if (!entity.containsKey(key)) {
						continue;
					}

					set(key, entry.getValue());

				}

			}

			private void map(Object proxy, Method method, ResultSet rs)
					throws SQLException {

				ResultSetMetaData meta = rs.getMetaData();
				for (int i = 0; i < meta.getColumnCount(); i++) {

					// 定義されていないキーは無視
					String key = meta.getColumnLabel(1 + i);
					if (!entity.containsKey(key)) {
						continue;
					}

					set(key, rs.getObject(key));

				}

			}

			private void map(Object proxy, Method method, File file) {

				// ファイルの読み込み
				try (InputStream in = new BufferedInputStream(new FileInputStream(file))) {

					String name = file.getName().toLowerCase();
					if (name.endsWith(".dat")) {

						Map<? extends Object, ? extends Object> map = SerializationUtils.deserialize(new CipherInputStream(in, Tkyz.decrypt()));

						map(proxy, method, map);

					} else if (name.endsWith(".properties")) {

						Properties prop = new Properties();
						prop.load(in);

						map(proxy, method, prop);

//					} else if (name.endsWith(".json")) {
//						throw new UnsupportedOperationException();
//
//					} else if (name.endsWith(".yml") || name.endsWith(".yaml")) {
//						throw new UnsupportedOperationException();
//
//					} else if (name.endsWith(".xml")) {
//						throw new UnsupportedOperationException();

					} else {
						throw new IOException();
					}

					log.debug("read [file={}]", file);

				} catch (IOException e) {
					log.warn("read [file={}]", file, e);
				}

				// ファイルの書き込み
				Runtime.getRuntime().addShutdownHook(new Thread(() -> {

					boolean tag = true;
					try (OutputStream out = new CipherOutputStream(new BufferedOutputStream(new FileOutputStream(file)), Tkyz.encrypt())) {

						SerializationUtils.serialize((Serializable)entity, out);

						log.debug("write [file={}]", file);

					} catch (IOException e) {
						tag = false;
						log.warn("write [file={}]", file, e);
					}

					if (tag) {

						String suffix = ".tag_" + CoreUtils.now("yyyyMMdd_HHmmss");
						File backup = new File(file.getParent(), file.getName() + suffix);

						try {

							Files.copy(file.toPath(), backup.toPath());

							log.debug("write [file={}]", backup);

						} catch (IOException e) {
							log.warn("write [file={}]", backup, e);
						}

					}

				}));

			}

			private void set(String key, Object val) {

				// TODO: キャスト
//				try {
//					val = CoreUtils.cast(method.getReturnType(), val);
//				} catch (UnsupportedOperationException e) {
//				}

				entity.put(key, (Serializable)val);

			}

			private Object get(String key) {
				return entity.get(key);
			}

		});

	}

//	@Deprecated
//	public default List<? extends Serializable> array(final String... keys) {
//
//		List<Serializable> vals = new ArrayList<>();
//
//		for (String key : keys) {
//			vals.add((Serializable)get(key));
//		}
//
//		return vals;
//
//	}
//
//	public default String join(final String delim, final String... keys) {
//
//		List<String> vals = new ArrayList<>();
//
//		for (String key : keys) {
//
//			Object val = map().get(key);
//
//			vals.add(null == val ? "" : val.toString());
//
//		}
//
//		return String.join(delim, vals);
//
//	}
//
//	/**
//	 * このインスタンスのハッシュ値を返します。
//	 *
//	 * @return ハッシュ値
//	 */
//	public default String sha256() {
//
//		byte[] bytes = SerializationUtils.serialize((Serializable)map());
//
//		return DigestUtils.sha256Hex(bytes);
//
//	}

}
