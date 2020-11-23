package jp.tkyz.cmd.example;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.Serializable;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.spec.KeySpec;
import java.security.spec.RSAPrivateKeySpec;
import java.security.spec.RSAPublicKeySpec;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.UUID;

import javax.crypto.Cipher;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;

import org.apache.commons.lang3.SerializationUtils;
import org.apache.commons.lang3.SystemUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.datastax.oss.driver.api.core.CqlIdentifier;
import com.datastax.oss.driver.api.core.CqlSession;
import com.datastax.oss.driver.api.core.metadata.Metadata;
import com.datastax.oss.driver.api.core.metadata.Node;
import com.datastax.oss.driver.api.core.metadata.schema.AggregateMetadata;
import com.datastax.oss.driver.api.core.metadata.schema.ColumnMetadata;
import com.datastax.oss.driver.api.core.metadata.schema.FunctionMetadata;
import com.datastax.oss.driver.api.core.metadata.schema.FunctionSignature;
import com.datastax.oss.driver.api.core.metadata.schema.IndexMetadata;
import com.datastax.oss.driver.api.core.metadata.schema.KeyspaceMetadata;
import com.datastax.oss.driver.api.core.metadata.schema.TableMetadata;
import com.datastax.oss.driver.api.core.metadata.schema.ViewMetadata;
import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

import jp.tkyz.Tkyz;
import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.Main;
import jp.tkyz.core.concurrent.IoWorker;

public class Example implements Main {

	private static final Logger log = LoggerFactory.getLogger(Example.class);

	public static void main(String... args)
			throws Exception {
		Main.call(args);
	}

	private static boolean branch = false;

	@Override
	public Void call()
			throws Exception {

		if (!branch) {
			branch = true;
			main();

		} else {
			branch();
		}

		return null;

	}

	private void main()
			throws Exception {

		for (int i = 0; i < CoreUtils.CPU_CORE << 1; i++) {
			IoWorker.add(Main.of(Example.class));
		}

	}

	private void branch()
			throws Exception {

//		jna();
//		aes();
//		rsa();
//		cassandra();

		Thread.sleep((long)(Math.random() * 3000));

	}

	private Void jna()
			throws Exception {

		CLib.instance.printf("jna printf" + System.lineSeparator());

		User32.instance.MessageBoxA(null, "message", "title", 0);

		return null;

	}

	private static interface CLib extends Library {

		public static final CLib instance = Native.load(SystemUtils.IS_OS_WINDOWS ? "msvcrt" : "c", CLib.class);

		public void printf(String format, Object... args);

	}

	private static interface User32 extends Library {

		public static final User32 instance = Native.load("user32", User32.class);

		public int MessageBoxA(Pointer hWnd, String lpText, String lpCaption, int uType);

    }
 
	private Void aes()
			throws Exception {

		_crypt("abcde", Tkyz.encrypt(), Tkyz.decrypt());

		return null;

	}

	private Void rsa()
			throws Exception {

		// 鍵を作成
		Key privateKey = null;
		Key publicKey  = null;
		{

			KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
			gen.initialize(4096);

			KeyPair pair = gen.generateKeyPair();

			KeyFactory factoty = KeyFactory.getInstance("RSA");

			KeySpec privateKeySpec = factoty.getKeySpec(pair.getPrivate(), RSAPrivateKeySpec.class);
			KeySpec publicKeySpec  = factoty.getKeySpec(pair.getPublic(),  RSAPublicKeySpec.class);

			privateKey = factoty.generatePrivate(privateKeySpec);
			publicKey  = factoty.generatePublic(publicKeySpec);

		}

		// 秘密鍵で暗号化、公開鍵で複合化
		{

			Cipher encrypt = Cipher.getInstance("RSA/ECB/PKCS1Padding");
			encrypt.init(Cipher.ENCRYPT_MODE, privateKey);

			Cipher decript = Cipher.getInstance("RSA/ECB/PKCS1Padding");
			decript.init(Cipher.DECRYPT_MODE, publicKey);

			_crypt("abcde", encrypt, decript);

		}

		// 秘密鍵で暗号化、公開鍵で複合化
		{

			Cipher encrypt = Cipher.getInstance("RSA/ECB/PKCS1Padding");
			encrypt.init(Cipher.ENCRYPT_MODE, publicKey);

			Cipher decript = Cipher.getInstance("RSA/ECB/PKCS1Padding");
			decript.init(Cipher.DECRYPT_MODE, privateKey);

			_crypt("abcde", encrypt, decript);

		}

		return null;

	}

	private void _crypt(Serializable origin, Cipher encrypt, Cipher decript)
			throws IOException {

		Serializable obj1 = origin;
		Serializable obj2 = null;

		File tmp = Files.createTempFile(null, null).toFile();

		// 署名
//		Signature sign = Signature.getInstance("SHA256withRSA");
//		SignedObject signed = new SignedObject(entity, keys.privateKey(), sign);

		// 暗号化・シリアライズ
		try (BufferedOutputStream out = new BufferedOutputStream(new CipherOutputStream(new FileOutputStream(tmp), encrypt))) {
			SerializationUtils.serialize(obj1, out);
		}

		// 複合化・デシリアライズ
		try (BufferedInputStream in = new BufferedInputStream(new CipherInputStream(new FileInputStream(tmp), decript))) {
			obj2 = SerializationUtils.deserialize(in);
		}

		// 署名を検証
//		if (signed.verify(keys.publicKey(), sign)) {
//		}
//		entity2 = (Entity)signed.getObject();

		log.debug("{}", obj1);
		log.debug("{}", obj2);
		log.debug("{}", obj1.equals(obj2));

	}

	private Void cassandra() {

		boolean system = true;

		InetSocketAddress node = new InetSocketAddress("example." + Tkyz.domain, 9042);
		try (CqlSession session = CqlSession.builder().addContactPoint(node).withLocalDatacenter("datacenter1").build()) {

			Metadata metadata = session.getMetadata();

			log.debug("cassandra:");
			log.debug("  nodes:");
			for (Entry<UUID, Node> entry : metadata.getNodes().entrySet()) {

				UUID key = entry.getKey();
				Node val = entry.getValue();

				log.debug("    - name: {}", key);
				log.debug("      cassandra-version: {}", val.getCassandraVersion());
				log.debug("      host-id: {}", val.getHostId());
				log.debug("      datacenter: {}", val.getDatacenter());
				log.debug("      rack: {}", val.getRack());
				log.debug("      distance: {}", val.getDistance());
				log.debug("      schema-version: {}", val.getSchemaVersion());
				log.debug("      open-connections: {}", val.getOpenConnections());
				log.debug("      state: {}", val.getState());
				log.debug("      up-since-millis: {}", val.getUpSinceMillis());
				log.debug("      extras: {}", val.getExtras());
				log.debug("      end-point: {}", val.getEndPoint());
				log.debug("      listen-address: {}", val.getListenAddress());
				log.debug("      broadcast-address: {}", val.getBroadcastAddress());
				log.debug("      broadcast-rpc-address: {}", val.getBroadcastRpcAddress());

			}

			Set<String> system_ks = new HashSet<>();
			system_ks.add("system_auth");
			system_ks.add("system_schema");
			system_ks.add("system_distributed");
			system_ks.add("system");
			system_ks.add("system_traces");

			log.debug("  keyspaces:");
			for (Entry<CqlIdentifier, KeyspaceMetadata> entry1 : metadata.getKeyspaces().entrySet()) {

				CqlIdentifier    key1 = entry1.getKey();
				KeyspaceMetadata val1 = entry1.getValue();

				if (!system && system_ks.contains(key1.asInternal())) {
					continue;
				}

				log.debug("    - name: {}", key1);

				log.debug("      tables:");
				for (Entry<CqlIdentifier, TableMetadata> entry2 : val1.getTables().entrySet()) {

					CqlIdentifier key2 = entry2.getKey();
					TableMetadata val2 = entry2.getValue();

					log.debug("        - name: {}", key2);

					Map<ColumnMetadata, Integer> pkey = new HashMap<>();
					for (int i = 0; i < val2.getPrimaryKey().size(); i++) {
						pkey.put(val2.getPrimaryKey().get(i), Integer.valueOf(1 + i));
					}

					log.debug("          columns:");
					for (Entry<CqlIdentifier, ColumnMetadata> entry3 : val2.getColumns().entrySet()) {

						CqlIdentifier  key3 = entry3.getKey();
						ColumnMetadata val3 = entry3.getValue();

						log.debug("            - name: {}", key3);
						log.debug("              type: {}", val3.getType());
						if (!pkey.containsKey(val3)) {
							continue;
						}

						log.debug("              pkey: {}", pkey.get(val3));

					}

					log.debug("          indexes:");
					for (Entry<CqlIdentifier, IndexMetadata> entry3 : val2.getIndexes().entrySet()) {

						CqlIdentifier key3 = entry3.getKey();
						IndexMetadata val3 = entry3.getValue();

						log.debug("            - name: {}", key3);
						log.debug("              type: {}", val3);

					}

				}

				log.debug("      views:");
				for (Entry<CqlIdentifier, ViewMetadata> entry2 : val1.getViews().entrySet()) {

					CqlIdentifier key2 = entry2.getKey();
					ViewMetadata  val2 = entry2.getValue();

					log.debug("        - name: {}", key2);

					log.debug("          columns:");
					for (Entry<CqlIdentifier, ColumnMetadata> entry3 : val2.getColumns().entrySet()) {

						CqlIdentifier  key3 = entry3.getKey();
						ColumnMetadata val3 = entry3.getValue();

						log.debug("            - name: {}", key3);
						log.debug("              type: {}", val3.getType());

					}

				}

				log.debug("      functions:");
				for (Entry<FunctionSignature, FunctionMetadata> entry2 : val1.getFunctions().entrySet()) {

					FunctionSignature key2 = entry2.getKey();
					FunctionMetadata  val2 = entry2.getValue();

					log.debug("        - name: {}", key2);
					log.debug("          value: {}", val2);

				}

				log.debug("      aggregates:");
				for (Entry<FunctionSignature, AggregateMetadata> entry2 : val1.getAggregates().entrySet()) {

					FunctionSignature key2 = entry2.getKey();
					AggregateMetadata val2 = entry2.getValue();

					log.debug("        - name: {}", key2);
					log.debug("          value: {}", val2);

				}

			}

		}

		return null;

	}

}
