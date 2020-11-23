package jp.tkyz.core.dao;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

import jp.tkyz.core.CoreUtils;
import jp.tkyz.core.model.Entity;
import jp.tkyz.core.reflect.UnimplementedException;

public final class Dao {

	/** フェッチサイズ */
	public static final int FETCH_SIZE = 1 << 16;

	/** バルクサイズ */
	public static final int BULK_SIZE = 1 << 13;

	public static final <T extends Entity> void truncate(final Class<T> type, final Connection con)
			throws SQLException {

		throw new UnimplementedException();

	}

	public static final <T extends Entity> List<T> list(final Class<T> type, final Connection con, final CharSequence query, final Object... params)
			throws SQLException {
		return list(type, con, query, List.of(params));
	}

	public static final <T extends Entity> List<T> list(final Class<T> type, final Connection con, final CharSequence query, final Collection<Object> params)
			throws SQLException {

		List<T> entities = new LinkedList<>();

		try (PreparedStatement stmt = con.prepareStatement(query.toString())) {

			stmt.setFetchSize(FETCH_SIZE);

			bind(stmt);

			try (ResultSet rs = stmt.executeQuery()) {
				while (rs.next()) {

					T entity = Entity.of(type);
					entity.map(rs);

					entities.add(entity);

				}
			}

		}

		return entities;

	}

	public static final <T extends Entity> T one(final Class<T> type, final Connection con, final CharSequence query, final Object... params)
			throws SQLException {
		return one(type, con, query, List.of(params));
	}

	public static final <T extends Entity> T one(final Class<T> type, final Connection con, final CharSequence query, final Collection<Object> params)
			throws SQLException {

		T entity = null;

		try (PreparedStatement stmt = con.prepareStatement(query.toString())) {

			stmt.setFetchSize(2);

			bind(stmt);

			try (ResultSet rs = stmt.executeQuery()) {

				if (rs.next()) {
					entity = Entity.of(type);
					entity.map(rs);
				}

				if (null == entity || rs.next()) {
					throw new IllegalArgumentException("レコードをユニークに特定できません。");
				}

			}

		}

		return entity;

	}

	public static final <T extends Entity> T first(final Class<T> type, final Connection con, final CharSequence query, final Object... params)
			throws SQLException {
		return first(type, con, query, List.of(params));
	}

	public static final <T extends Entity> T first(final Class<T> type, final Connection con, final CharSequence query, final Collection<Object> params)
			throws SQLException {

		T entity = null;

		try (PreparedStatement stmt = con.prepareStatement(query.toString())) {

			stmt.setFetchSize(1);

			bind(stmt);

			try (ResultSet rs = stmt.executeQuery()) {

				if (rs.next()) {
					entity = Entity.of(type);
					entity.map(rs);
				}

			}

		}

		return entity;

	}

	public static final int ins(final Connection con, final Entity... entities)
			throws SQLException {
		return ins(con, List.of(entities));
	}

	public static final int ins(final Connection con, final Collection<Entity> entities)
			throws SQLException {

		int count = 0;

		if (!CoreUtils.empty(entities)) {

			throw new UnimplementedException();

		}

		return count;

	}

	public static final int upd(final Connection con, final Entity... entities)
			throws SQLException {
		return upd(con, List.of(entities));
	}

	public static final int upd(final Connection con, final Collection<Entity> entities)
			throws SQLException {

		int count = 0;

		if (!CoreUtils.empty(entities)) {

			throw new UnimplementedException();

		}

		return count;

	}

	public static final int del(final Connection con, final Entity... entities)
			throws SQLException {
		return upd(con, List.of(entities));
	}

	public static final int del(final Connection con, final Collection<Entity> entities)
			throws SQLException {

		int count = 0;

		if (!CoreUtils.empty(entities)) {

			throw new UnimplementedException();

		}

		return count;

	}

	public static final void bind(final PreparedStatement stmt, final Object... params)
			throws SQLException {
		bind(stmt, List.of(params));
	}

	public static final void bind(final PreparedStatement stmt, final Collection<Object> params)
			throws SQLException {

		Iterator<Object> ite = params.iterator();
		for (int i = 0; ite.hasNext(); i++) {
			stmt.setObject(i++, ite.next());
		}

	}

	public static interface Catalog extends Entity {

		public String CATALOG_NAME();

		public String TABLE_CATALOG();

	}

	/**
	 * カタログの一覧を取得します。
	 *
	 * @param con コネクション
	 * @return カタログの一覧
	 * @throws SQLException 例外
	 */
	public static final List<Catalog> catalogs(final Connection con)
			throws SQLException {

		List<Catalog> entities = new LinkedList<>();

		DatabaseMetaData meta = con.getMetaData();
		try (ResultSet rs = meta.getCatalogs()) {
			while (rs.next()) {

				Catalog entity = Entity.of(Catalog.class);
				entity.map(rs);

				entities.add(entity);

			}
		}

		return entities;

	}

	public static interface Schema extends Entity {

		public String SCHEMA_NAME();

		public String TABLE_SCHEM();

	}

	/**
	 * スキーマの一覧を取得します。
	 *
	 * @param con コネクション
	 * @param catalog カタログ
	 * @return スキーマの一覧
	 * @throws SQLException 例外
	 */
	public static final List<Schema> schemas(final Connection con, final Catalog catalog)
			throws SQLException {

		List<Schema> entities = new LinkedList<>();

		String catalogName = null == catalog ? null : CoreUtils.nvl(catalog.CATALOG_NAME(), catalog.TABLE_CATALOG());

		DatabaseMetaData meta = con.getMetaData();
		try (ResultSet rs = meta.getSchemas(catalogName, null)) {
			while (rs.next()) {

				Schema entity = Entity.of(Schema.class);
				entity.map(rs);

				entities.add(entity);

			}
		}

		return entities;

	}

	public static interface Table extends Entity {

		public String TABLE_NAME();

		public String TABLE_TYPE();

	}

	/**
	 * テーブルの一覧を取得します。
	 *
	 * @param con コネクション
	 * @param catalog カタログ
	 * @param schema スキーマ
	 * @return テーブルの一覧
	 * @throws SQLException 例外
	 */
	public static final List<Table> tables(final Connection con, final Catalog catalog, final Schema schema)
			throws SQLException {

		List<Table> entities = new LinkedList<>();

		String catalogName = null == catalog ? null : CoreUtils.nvl(catalog.CATALOG_NAME(), catalog.TABLE_CATALOG());
		String schemaName  = null == schema  ? null : CoreUtils.nvl(schema.SCHEMA_NAME(),   schema.TABLE_SCHEM());

		DatabaseMetaData meta = con.getMetaData();
		try (ResultSet rs = meta.getTables(catalogName, schemaName, null, null)) {
			while (rs.next()) {

				Table entity = Entity.of(Table.class);
				entity.map(rs);

				entities.add(entity);

			}
		}

		return entities;

	}

	public static interface Column extends Entity {

		public String COLUMN_NAME();

	}

	/**
	 * カラムの一覧を取得します。
	 *
	 * @param con コネクション
	 * @param catalog カタログ
	 * @param schema スキーマ
	 * @param table テーブル
	 * @return カラムの一覧
	 * @throws SQLException 例外
	 */
	public static final List<Column> columns(final Connection con, final Catalog catalog, final Schema schema, final Table table)
			throws SQLException {

		List<Column> entities = new LinkedList<>();

		String catalogName = null == catalog ? null : CoreUtils.nvl(catalog.CATALOG_NAME(), catalog.TABLE_CATALOG());
		String schemaName  = null == schema  ? null : CoreUtils.nvl(schema.SCHEMA_NAME(),   schema.TABLE_SCHEM());
		String tableName   = null == table   ? null : table.TABLE_NAME();

		// TODO: pk
//		try (ResultSet rs = meta.getPrimaryKeys(catalogName, schemaName, tableName)) {
//			while (rs.next()) {
//				String pk = rs.getString("COLUMN_NAME");
//			}
//		}

		DatabaseMetaData meta = con.getMetaData();
		try (ResultSet rs = meta.getColumns(catalogName, schemaName, tableName, null)) {
			while (rs.next()) {

				Column entity = Entity.of(Column.class);
				entity.map(rs);

				entities.add(entity);

			}
		}

		return entities;

	}

}
