class AddJapaneseSearch < ActiveRecord::Migration[8.1]
  def up
    enable_extension "pg_trgm"

    # Denormalised text column holding Japanese title + dek for trigram search.
    # Kept in sync by ArticleTranslation#sync_search_vector.
    add_column :articles, :ja_search_text, :text, default: ""

    # GIN trigram index — supports fast LIKE/ILIKE and the % similarity operator.
    execute <<~SQL
      CREATE INDEX index_articles_on_ja_search_text_trgm
      ON articles
      USING gin (ja_search_text gin_trgm_ops);
    SQL

    # Backfill from existing Japanese translations.
    execute <<~SQL
      UPDATE articles a
      SET ja_search_text = coalesce(t.title, '') || ' ' || coalesce(t.dek, '')
      FROM article_translations t
      WHERE t.article_id = a.id
        AND t.locale = 'ja';
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_articles_on_ja_search_text_trgm;"
    remove_column :articles, :ja_search_text
    disable_extension "pg_trgm"
  end
end
