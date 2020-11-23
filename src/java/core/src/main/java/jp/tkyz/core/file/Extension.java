package jp.tkyz.core.file;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public final class Extension {

	/** ヘッダ定義 */
	private static final List<Extension> EXTS = new ArrayList<Extension>() {

		/** シリアルバージョンUID */
		private static final long serialVersionUID = 8015277960114068728L;

		{
			add(new Extension("flv", 'F', 'L', 'V', 0x01, null, 0x00, 0x00, 0x00, 0x09));
			add(new Extension("mp4", null, null, null, null, 'f', 't', 'y', 'p'));
			add(new Extension("mpg", 0x00, 0x00, 0x01, 0xba, null, 0x00));
			add(new Extension("mkv", 0x1a, 0x45, 0xdf, 0xa3, null, 0x42));
			add(new Extension("avi", 'R', 'I', 'F', 'F', null, null, null, null, 'A', 'V', 'I', ' ', 'L', 'I', 'S', 'T', null, null, null, null, 'h', 'd', 'r', 'l', 'a', 'v', 'i', 'h'));
			add(new Extension("ogg", 0x4f, 0x67, 0x67, 0x53, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00));
			add(new Extension("wmv", 0x30, 0x26, 0xb2, 0x75, 0x8e, 0x66, 0xcf, 0x11, 0xa6, 0xd9, 0x00, 0xaa, 0x00, 0x62, 0xce, 0x6c));
			add(new Extension("jpg", 0xff, 0xd8));
			add(new Extension("png", 0x89, 'P', 'N', 'G'));
			add(new Extension("gif", 'G', 'I', 'F', '8', '7', 'a'));
			add(new Extension("gif", 'G', 'I', 'F', '8', '9', 'a'));
		}

	};

	private static int MAX;

	/** 拡張子 */
	private String value = null;

	/** ヘッダー */
	private Byte[] header = null;

	private Extension(final String value, final Object... header) {

		MAX = Math.max(MAX, header.length);

		this.value = value;
		this.header = new Byte[header.length];

		for (int i = 0; i < header.length; i++) {

			Byte b = null;
			if (null != header[i]) {

				if (header[i] instanceof Number) {
					b = Byte.valueOf(((Number)header[i]).byteValue());

				} else if (header[i] instanceof Character) {
					b = Byte.valueOf((byte)((Character)header[i]).charValue());

				} else {
					throw new RuntimeException(header[i].getClass().getName());
				}

			}

			this.header[i] = b;

		}

	}

	public static String get(final String name)
			throws IOException {

		String ret = null;

		File file = new File(name);

		if (file.exists()) {
			ret = get(file);

		} else {

			int dot = name.lastIndexOf(".");

			ret = -1 == dot ? null : name.substring(dot + 1);

		}

		return ret;

	}

	public static String get(final File file)
			throws IOException {

		String ret = null;

		if (file.exists()) {

			try (InputStream in = new BufferedInputStream(new FileInputStream(file))) {
				ret = get(in);
			}

		} else {
			ret = get(file.getName());
		}

		return ret;

	}

	public static String get(final InputStream in)
			throws IOException {

		String ret = null;

		byte[] buf = new byte[MAX];
		in.read(buf, 0, buf.length);

		for (Extension ext : EXTS) {

			boolean match = true;
			for (int i = 0; match && i < ext.header.length; i++) {

				Byte b = ext.header[i];
				if (null == b) {
					continue;
				}

				match &= b.byteValue() == buf[i];

			}

			if (match) {
				ret = ext.value();
				break;
			}

		}

		return ret;

	}

	private String value() {
		return value;
	}

}
