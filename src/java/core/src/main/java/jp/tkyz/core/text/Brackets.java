package jp.tkyz.core.text;

import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

public final class Brackets {

	private static final Brackets instance = new Brackets();

	private final Map<String, String> sted = new HashMap<String, String>();
	private final Map<String, String> edst = new HashMap<String, String>();

	private Brackets() {

		// 0括弧
		add("(", ")");
		add("（", "）");

		// 1括弧
		add("<", ">");
		add("＜", "＞");
		add("≪", "≫");
		add("〈", "〉");
		add("《", "》");
		add("｢", "｣");
		add("「", "」");

		// 2括弧
		add("[", "]");
		add("［", "］");
		add("〔", "〕");
		add("【", "】");

		// 3括弧
		add("{", "}");
		add("｛", "｝");

	}

	private void add(String start, String end) {
		sted.put(start, end);
		edst.put(end, start);
	}

	public static Set<Entry<String, String>> pairs() {
		return instance.sted.entrySet();
	}

	public static String start(String end) {
		return instance.edst.get(end);
	}

	public static String end(String start) {
		return instance.sted.get(start);
	}

}
