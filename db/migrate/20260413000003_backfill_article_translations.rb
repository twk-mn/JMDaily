class BackfillArticleTranslations < ActiveRecord::Migration[8.1]
  def up
    # Seed one English translation per existing article, copying title/slug/dek.
    execute <<~SQL
      INSERT INTO article_translations (article_id, locale, title, slug, dek, created_at, updated_at)
      SELECT id, 'en', title, slug, COALESCE(dek, ''), created_at, updated_at
      FROM articles
      ON CONFLICT DO NOTHING
    SQL

    # Re-point Action Text body records from Article → ArticleTranslation so that
    # rich-text content is now owned by the translation, not the bare article.
    execute <<~SQL
      UPDATE action_text_rich_texts artr
      SET record_type = 'ArticleTranslation',
          record_id   = at.id
      FROM article_translations at
      WHERE artr.record_type = 'Article'
        AND artr.name        = 'body'
        AND artr.record_id   = at.article_id
        AND at.locale        = 'en'
    SQL
  end

  def down
    # Restore Action Text body ownership back to Article.
    execute <<~SQL
      UPDATE action_text_rich_texts artr
      SET record_type = 'Article',
          record_id   = at.article_id
      FROM article_translations at
      WHERE artr.record_type = 'ArticleTranslation'
        AND artr.name        = 'body'
        AND artr.record_id   = at.id
        AND at.locale        = 'en'
    SQL

    execute "DELETE FROM article_translations WHERE locale = 'en'"
  end
end
