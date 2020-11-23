package jp.tkyz;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.util.Properties;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import org.apache.commons.codec.DecoderException;
import org.apache.commons.codec.binary.Hex;

import jp.tkyz.core.CoreUtils;

public final class Tkyz {

	public static final String domain = "tkyz.jp";

	public static final String namespace = "jp.tkyz";

	private static final File home = new File(System.getProperty("user.home"), "home");

	private static Cipher encrypt = null;

	private static Cipher decrypt = null;

	private Tkyz() {
	}

	public static File home() {

		if (!Files.isDirectory(home.toPath())) {
			throw new UnsupportedOperationException();
		}

		return home;

	}

	private static File home(String... childs) {
		return CoreUtils.file(home(), childs);
	}

	public static File mnt(String... childs) {
		return CoreUtils.file(home(CoreUtils.current().getMethodName()), childs);
	}

	public static File var(String... childs) {
		return CoreUtils.file(home(CoreUtils.current().getMethodName()), childs);
	}

	private static File secrets(String... childs) {
		return CoreUtils.file(home("." + CoreUtils.current().getMethodName()), childs);
	}

	private static synchronized void cipher() {

		if (null == encrypt || null == decrypt) {
			try {

				Properties prop = new Properties();

				File keys = secrets("keys", "aes-256");
				try (InputStream in = new BufferedInputStream(new FileInputStream(keys))) {
					prop.load(in);
				}

				Key key = new SecretKeySpec(Hex.decodeHex(prop.getProperty("key")), "AES");
				IvParameterSpec iv = new IvParameterSpec(Hex.decodeHex(prop.getProperty("iv")));

				Cipher enc = Cipher.getInstance("AES/CBC/PKCS5Padding");
				enc.init(Cipher.ENCRYPT_MODE, key, iv);

				Cipher dec = Cipher.getInstance("AES/CBC/PKCS5Padding");
				dec.init(Cipher.DECRYPT_MODE, key, iv);

				encrypt = enc;
				decrypt = dec;

			} catch (IOException | DecoderException | NoSuchAlgorithmException | NoSuchPaddingException | InvalidKeyException | InvalidAlgorithmParameterException e) {
				throw new UnsupportedOperationException(e);
			}
		}

	}

	public static Cipher encrypt() {

		if (null == encrypt) {
			cipher();
		}

		return encrypt;

	}

	public static Cipher decrypt() {

		if (null == decrypt) {
			cipher();
		}

		return decrypt;

	}

}
