# The full-text search trigger and function are defined in a migration using raw SQL,
# which db/schema.rb cannot capture. This file creates them in the test database so
# search specs work correctly.
#
# Note: the trigger function uses NEW.title/NEW.dek directly (not a self-join)
# because on BEFORE INSERT the row doesn't exist in the table yet.
RSpec.configure do |config|
  config.before(:suite) do
    conn = ActiveRecord::Base.connection

    conn.execute("DROP TRIGGER IF EXISTS articles_search_vector_update ON articles")
    conn.execute("DROP FUNCTION IF EXISTS articles_search_vector_trigger()")
    conn.execute("DROP FUNCTION IF EXISTS articles_search_vector(bigint)")

    conn.execute(<<~SQL)
      CREATE FUNCTION articles_search_vector(article_id bigint)
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

    conn.execute(<<~SQL)
      CREATE FUNCTION articles_search_vector_trigger()
      RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(NEW.dek, '')), 'B');
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    conn.execute(<<~SQL)
      CREATE TRIGGER articles_search_vector_update
      BEFORE INSERT OR UPDATE OF title, dek, search_vector
      ON articles
      FOR EACH ROW EXECUTE FUNCTION articles_search_vector_trigger();
    SQL
  end
end
