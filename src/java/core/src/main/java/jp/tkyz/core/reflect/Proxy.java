package jp.tkyz.core.reflect;

import java.lang.reflect.InvocationHandler;

public final class Proxy {

	private Proxy() {
	}

//	@SuppressWarnings("unchecked")
//	public static <T> T of(final String type, InvocationHandler handler)
//				throws ClassNotFoundException {
//		return (T)of(Class.forName(type), handler);
//	}
//
//	@SuppressWarnings("unchecked")
//	public static <T extends I, I> T of(String type, I impl)
//			throws ClassNotFoundException {
//		return (T)of(Class.forName(type), impl);
//	}

	@SuppressWarnings("unchecked")
	public static <T> T of(Class<T> type, InvocationHandler handler) {
		return (T)java.lang.reflect.Proxy.newProxyInstance(type.getClassLoader(), new Class<?>[] { type }, handler);
	}

//	@SuppressWarnings("unchecked")
//	public static <T extends I, I> T of(Class<T> type, I impl) {
//
//		Class<I> itype = (Class<I>)impl.getClass();
//
//		return of(type, (proxy, method, args) -> {
//
//			if (!method.getDeclaringClass().isAssignableFrom(itype)) {
//				assert false;
//			}
//
//			return method.invoke(impl, args);
//
//		});
//
//	}
//
//	@SuppressWarnings("unchecked")
//	public static <T extends I, I> T of(T origin, I impl) {
//
//		Class<T> type  = (Class<T>)origin.getClass();
//		Class<I> itype = (Class<I>)impl.getClass();
//
//		return (T)java.lang.reflect.Proxy.newProxyInstance(type.getClassLoader(), new Class<?>[] { itype }, (proxy, method, args) -> {
//
//			Object ret = null;
//
//			if (method.getDeclaringClass().isAssignableFrom(itype)) {
//				ret = method.invoke(impl, args);
//
//			} else {
//				ret = method.invoke(origin, args);
//			}
//
//			return ret;
//
//		});
//
//	}

}
