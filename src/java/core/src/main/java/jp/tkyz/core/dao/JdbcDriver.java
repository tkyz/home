package jp.tkyz.core.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jp.tkyz.core.CoreUtils;

public final class JdbcDriver {

	/** ロガー */
	private static final Logger log = LoggerFactory.getLogger(JdbcDriver.class);

	public static final JdbcDriver hive      = new JdbcDriver("org.apache.hive.jdbc.HiveDriver", "jdbc:hive2://{host}[:{port}][/{database}]", 10000);

	public static final JdbcDriver derby_emb = new JdbcDriver("org.apache.derby.jdbc.EmbeddedDriver", "jdbc:derby:{file}", 0);

	public static final JdbcDriver derby_srv = new JdbcDriver("org.apache.derby.jdbc.ClientDriver", "jdbc:derby://{host}[:{port}]/{file}", 1527);

	public static final JdbcDriver sqlite    = new JdbcDriver("org.sqlite.JDBC", "jdbc:sqlite:{file}", 0);

	public static final JdbcDriver mysql     = new JdbcDriver("com.mysql.cj.jdbc.Driver", "jdbc:mysql://{host}[:{port}]/[{database}]", 3306);

	public static final JdbcDriver mariadb   = new JdbcDriver("org.mariadb.jdbc.Driver", "jdbc:mariadb://{host}[:{port}]/[{database}]", 3306);

	public static final JdbcDriver pgsql     = new JdbcDriver("org.postgresql.Driver", "jdbc:postgresql://{host}[:{port}]/[{database}]", 5432);

	public static final JdbcDriver oracle    = new JdbcDriver("oracle.jdbc.OracleDriver", "jdbc:oracle:thin:@{host}[:{port}]/{database}", 1521);

	public static final JdbcDriver sqlserver = new JdbcDriver("com.microsoft.sqlserver.jdbc.SQLServerDriver", "jdbc:sqlserver://{host}[:{port}][;databaseName={database}]", 1433);

	private String driver = null;

	private String uri = null;

	private int port = 0;

	private JdbcDriver(String driver, String uri, int port) {
		this.driver = driver;
		this.uri    = uri;
		this.port   = port;
	}

	public String driver() {
		return driver;
	}

	public String uri() {
		return uri;
	}

	public int port() {
		return port;
	}

	public Connection open(String host, int port, String database, String user, String password)
			throws SQLException {

		Map<String, Object> map = new HashMap<>();
		if (!CoreUtils.empty(host)) {
			map.put("host", host);
		}
		map.put("port", Integer.valueOf(0 < port ? port : port()));
		if (!CoreUtils.empty(database)) {
			map.put("database", database);
			map.put("file",     database);
		}
		if (!CoreUtils.empty(user)) {
			map.put("user", user);
		}
		if (!CoreUtils.empty(password)) {
			map.put("password", password);
		}

		return open(map);

	}

	public Connection open(Map<String, Object> map)
			throws SQLException {

		Properties prop = new Properties();
		prop.putAll(map);

		return open(prop);

	}

	public Connection open(Properties prop)
			throws SQLException {

		try {
			Class.forName(driver());
		} catch (ClassNotFoundException e) {
			throw new RuntimeException(e);
		}

		// プレースホルダの置換
		String uri = uri();
		{

			Set<String> keys = new HashSet<>();
			keys.add("host");
			keys.add("port");
			keys.add("database");
			keys.add("file");

			for (String key : keys) {

				Object val = prop.get(key);

				uri = uri.replaceAll("\\[?(:?)\\{" + key + "\\}\\]?", CoreUtils.empty(val) ? "" : ("$1" + val));

			}

		}

		Connection con = DriverManager.getConnection(uri, prop);

		log.debug("jdbc connect. [driver={}, uri={}, prop={}]", driver(), uri, prop);

		return con;

	}

}
