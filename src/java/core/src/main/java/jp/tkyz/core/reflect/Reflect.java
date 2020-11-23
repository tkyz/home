package jp.tkyz.core.reflect;

import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;

public final class Reflect {

	private Reflect() {
	}

	/**
	 * デフォルトコンストラクタを使用して新しいインスタンスを作成します。
	 *
	 * @param type クラス
	 * @return インスタンス
	 */
	@SuppressWarnings("unchecked")
	public static <T> T of(final String type) {

		T ret = null;

		try {

			ret = (T)of(Class.forName(type));

		} catch (ReflectiveOperationException e) {
			throw new UnsupportedOperationException(e);
		}

		return ret;

	}

	/**
	 * デフォルトコンストラクタを使用して新しいインスタンスを作成します。
	 *
	 * @param type クラス
	 * @return インスタンス
	 */
	public static <T> T of(final Class<T> type) {

		T ret = null;

		try {

			Constructor<T> constructor = type.getDeclaredConstructor();
			constructor.setAccessible(true);

			ret = constructor.newInstance();

		} catch (ReflectiveOperationException e) {
			throw new UnsupportedOperationException(e);
		}

		return ret;

	}

	/**
	 * フィールドの値を取得します。
	 *
	 * @param instance インスタンス
	 * @param name フィールド名
	 * @return 値
	 * @throws NoSuchFieldException 例外
	 * @throws IllegalAccessException 例外
	 */
	public static <T> T get(final Object instance, final CharSequence name)
			throws NoSuchFieldException, IllegalAccessException {
		return get(instance, name, false);
	}

	/**
	 * フィールドの値を取得します。
	 *
	 * @param instance インスタンス
	 * @param name フィールド名
	 * @param force 強制取得
	 * @return 値
	 * @throws NoSuchFieldException 例外
	 * @throws IllegalAccessException 例外
	 */
	@SuppressWarnings("unchecked")
	public static <T> T get(final Object instance, final CharSequence name, final boolean force)
			throws NoSuchFieldException, IllegalAccessException {

		T value = null;

		Field field = field(instance, name, force);
		if (null != field) {
			value = (T)field.get(instance);
		}

		return value;

	}

	/**
	 * フィールドの値を設定します。
	 *
	 * @param instance インスタンス
	 * @param name フィールド名
	 * @param value 値
	 * @throws NoSuchFieldException 例外
	 * @throws IllegalAccessException 例外
	 */
	public static void set(final Object instance, final CharSequence name, final Object value)
			throws NoSuchFieldException, IllegalAccessException {
		set(instance, name, value, false);
	}

	/**
	 * フィールドの値を設定します。
	 *
	 * @param instance インスタンス
	 * @param name フィールド名
	 * @param value 値
	 * @param force 強制設定
	 * @throws NoSuchFieldException 例外
	 * @throws IllegalAccessException 例外
	 */
	public static void set(final Object instance, final CharSequence name, final Object value, final boolean force)
			throws NoSuchFieldException, IllegalAccessException {

		Field field = field(instance, name, force);
		if (null != field) {
			field.set(instance, value);
		}

	}

	private static Field field(final Object instance, final CharSequence name, final boolean accessible)
			throws NoSuchFieldException {

		Field field = null;

		if (null != instance) {

			Class<?> clazz = instance.getClass();

			if (!accessible) {
				field = clazz.getField(name.toString());

			} else {

				while (null == field) {

					try {

						field = clazz.getDeclaredField(name.toString());
						field.setAccessible(accessible);

					} catch (NoSuchFieldException e) {

						clazz = clazz.getSuperclass();
						if (null == clazz) {
							throw e;
						}

					}

				}

			}

		}

		return field;

	}

	/**
	 * getterメソッドを使用して値を設定します。
	 *
	 * @param instance 対象のオブジェクト
	 * @param name メソッド名
	 * @return 値
	 * @throws IllegalAccessException 例外
	 * @throws InvocationTargetException 例外
	 */
	public static <T> T getter(final Object instance, final CharSequence name)
			throws IllegalAccessException, InvocationTargetException {
		return getter(instance, name, false);
	}

	/**
	 * getterメソッドを使用して値を設定します。
	 *
	 * @param instance 対象のオブジェクト
	 * @param name メソッド名
	 * @param force 強制取得
	 * @return 値
	 * @throws IllegalAccessException 例外
	 * @throws InvocationTargetException 例外
	 */
	public static <T> T getter(final Object instance, final CharSequence name, final boolean force)
			throws IllegalAccessException, InvocationTargetException {

		T value = null;

		if (null != instance) {

			Class<?> clazz = instance.getClass();

			throw new UnimplementedException();

		}

		return value;

	}

	/**
	 * setterメソッドを使用して値を取得します。
	 *
	 * @param instance 対象のオブジェクト
	 * @param name メソッド名
	 * @param value 値
	 * @throws IllegalAccessException 例外
	 * @throws InvocationTargetException 例外
	 */
	public static <T> void setter(final Object instance, final CharSequence name, final T value)
			throws IllegalAccessException, InvocationTargetException {
		setter(instance, name, value, false);
	}

	/**
	 * setterメソッドを使用して値を取得します。
	 *
	 * @param instance 対象のオブジェクト
	 * @param name メソッド名
	 * @param value 値
	 * @param force 強制設定
	 * @throws IllegalAccessException 例外
	 * @throws InvocationTargetException 例外
	 */
	public static <T> void setter(final Object instance, final CharSequence name, final T value, final boolean force)
			throws IllegalAccessException, InvocationTargetException {

		if (null != instance) {

			Class<?> clazz = instance.getClass();

			throw new UnimplementedException();

		}

	}

}
