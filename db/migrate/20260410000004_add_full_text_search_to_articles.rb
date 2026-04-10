class AddFullTextSearchToArticles < ActiveRecord::Migration[8.0]
  def up
    # Add a tsvector column to store the pre-computed search vector
    add_column :articles, :search_vector, :tsvector

    # Index for fast full-text queries
    add_index :articles, :search_vector, using: :gin, name: "index_articles_on_search_vector"

    # Function to build the search vector from title, dek, and body
    # Weight A = title (highest), B = dek, C = body text
    # Body text lives in action_text_rich_texts joined by record_type/record_id
    execute <<~SQL
      CREATE OR REPLACE FUNCTION articles_search_vector(article_id bigint)
      RETURNS tsvector AS $$
        SELECT
          setweight(to_tsvector('english', coalesce(a.title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(a.dek, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(body.plain_text, '')), 'C')
        FROM articles a
        LEFT JOIN (
          SELECT record_id,
                 regexp_replace(body, '<[^>]*>', ' ', 'g') AS plain_text
          FROM action_text_rich_texts
          WHERE record_type = 'Article' AND name = 'body'
        ) body ON body.record_id = a.id
        WHERE a.id = article_id;
      $$ LANGUAGE sql STABLE;
    SQL

    # Trigger function to keep search_vector current on article changes
    execute <<~SQL
      CREATE OR REPLACE FUNCTION articles_search_vector_trigger()
      RETURNS trigger AS $$
      BEGIN
        NEW.search_vector := articles_search_vector(NEW.id);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      CREATE TRIGGER articles_search_vector_update
      BEFORE INSERT OR UPDATE OF title, dek, search_vector
      ON articles
      FOR EACH ROW EXECUTE FUNCTION articles_search_vector_trigger();
    SQL

    # Backfill all existing articles
    execute <<~SQL
      UPDATE articles
      SET search_vector = articles_search_vector(id);
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS articles_search_vector_update ON articles;"
    execute "DROP FUNCTION IF EXISTS articles_search_vector_trigger();"
    execute "DROP FUNCTION IF EXISTS articles_search_vector(bigint);"
    remove_index :articles, name: "index_articles_on_search_vector"
    remove_column :articles, :search_vector
  end
end
