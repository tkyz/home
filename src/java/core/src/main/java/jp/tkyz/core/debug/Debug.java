package jp.tkyz.core.debug;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.core.CoreUtils;

public final class Debug {

	/** ロガー */
	private static final Logger log = LoggerFactory.getLogger(Debug.class);

	public static void log(Object obj) {
		log("", obj, new HashSet<Object>());
	}

	private static void log(String base, Object obj, Set<Object> duplicated) {

		boolean toString = null == obj;
		if (!toString) {
			toString |= obj.getClass().isPrimitive();
			toString |= obj instanceof CharSequence;
			toString |= obj instanceof Date;
			toString |= obj instanceof Number;
			toString |= obj instanceof Boolean;
//			toString |= obj instanceof Serializable;
		}

		if (toString) {
			log.debug("{}={}", base, obj);

		} else if (!duplicated.add(obj)) {
			log.debug("{}={}", base, "...");

		} else {

			if (!CoreUtils.empty(base)) {
				base += ".";
			}

			if (obj instanceof Object[]) {

				Object[] item = (Object[])obj;
				for (int i = 0; i < item.length; i++) {
					log(base + "[" + i + "]", item[i], duplicated);
				}

			} else if (obj instanceof Collection) {

				List<?> tmp = new ArrayList<>((Collection<?>)obj);
				for (int i = 0; i < tmp.size(); i++) {
					log(base + "[" + i + "]", tmp.get(i), duplicated);
				}

			} else if (obj instanceof Map) {

				Map<?, ?> map = (Map<?, ?>)obj;
				for (Map.Entry<?, ?> entry : map.entrySet()) {

					Object key   = entry.getKey();
					Object value = entry.getValue();

					log(base + key, value, duplicated);

				}

			}

		}

	}

}
