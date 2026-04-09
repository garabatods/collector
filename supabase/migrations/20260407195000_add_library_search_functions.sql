create extension if not exists pg_trgm with schema extensions;

create index if not exists collectibles_search_document_idx
  on public.collectibles
  using gin (
    to_tsvector(
      'simple',
      coalesce(title, '') || ' ' ||
      coalesce(category, '') || ' ' ||
      coalesce(description, '') || ' ' ||
      coalesce(brand, '') || ' ' ||
      coalesce(series, '') || ' ' ||
      coalesce(franchise, '') || ' ' ||
      coalesce(line_or_series, '') || ' ' ||
      coalesce(character_or_subject, '') || ' ' ||
      coalesce(item_number, '') || ' ' ||
      coalesce(item_condition, '') || ' ' ||
      coalesce(box_status, '') || ' ' ||
      coalesce(notes, '')
    )
  );

create index if not exists tags_search_document_idx
  on public.tags
  using gin (
    to_tsvector('simple', coalesce(name, ''))
  );

create or replace function public.library_search_collectibles_base(
  search_text text default null,
  favorites_only boolean default false,
  grails_only boolean default false,
  duplicates_only boolean default false,
  has_photo_only boolean default false,
  selected_category text default null
)
returns setof public.collectibles
language sql
stable
security invoker
set search_path = public
as $$
  select c.*
  from public.collectibles c
  where c.user_id = auth.uid()
    and (not favorites_only or c.is_favorite)
    and (not grails_only or c.is_grail)
    and (not duplicates_only or c.is_duplicate)
    and (
      selected_category is null
      or btrim(selected_category) = ''
      or lower(c.category) = lower(btrim(selected_category))
    )
    and (
      not has_photo_only
      or exists (
        select 1
        from public.collectible_photos cp
        where cp.collectible_id = c.id
      )
    )
    and (
      search_text is null
      or btrim(search_text) = ''
      or to_tsvector(
        'simple',
        coalesce(c.title, '') || ' ' ||
        coalesce(c.category, '') || ' ' ||
        coalesce(c.description, '') || ' ' ||
        coalesce(c.brand, '') || ' ' ||
        coalesce(c.series, '') || ' ' ||
        coalesce(c.franchise, '') || ' ' ||
        coalesce(c.line_or_series, '') || ' ' ||
        coalesce(c.character_or_subject, '') || ' ' ||
        coalesce(c.item_number, '') || ' ' ||
        coalesce(c.item_condition, '') || ' ' ||
        coalesce(c.box_status, '') || ' ' ||
        coalesce(c.notes, '')
      ) @@ websearch_to_tsquery('simple', btrim(search_text))
      or exists (
        select 1
        from public.collectible_tags ct
        join public.tags t on t.id = ct.tag_id
        where ct.collectible_id = c.id
          and t.user_id = auth.uid()
          and to_tsvector('simple', coalesce(t.name, ''))
            @@ websearch_to_tsquery('simple', btrim(search_text))
      )
    );
$$;

create or replace function public.library_search_collectibles_page(
  search_text text default null,
  favorites_only boolean default false,
  grails_only boolean default false,
  duplicates_only boolean default false,
  has_photo_only boolean default false,
  selected_category text default null,
  sort_key text default 'newest',
  page_limit integer default 24,
  page_offset integer default 0
)
returns setof public.collectibles
language sql
stable
security invoker
set search_path = public
as $$
  select c.*
  from public.library_search_collectibles_base(
    search_text,
    favorites_only,
    grails_only,
    duplicates_only,
    has_photo_only,
    selected_category
  ) c
  order by
    case when sort_key = 'titleAscending' then lower(c.title) end asc,
    case when sort_key = 'titleDescending' then lower(c.title) end desc,
    case when sort_key = 'category' then lower(c.category) end asc,
    case when sort_key = 'category' then lower(c.title) end asc,
    case when sort_key = 'oldest' then c.created_at end asc,
    case when sort_key = 'newest' then c.created_at end desc,
    c.created_at desc
  limit greatest(page_limit, 1)
  offset greatest(page_offset, 0);
$$;

create or replace function public.library_search_collectibles_count(
  search_text text default null,
  favorites_only boolean default false,
  grails_only boolean default false,
  duplicates_only boolean default false,
  has_photo_only boolean default false,
  selected_category text default null
)
returns bigint
language sql
stable
security invoker
set search_path = public
as $$
  select count(*)::bigint
  from public.library_search_collectibles_base(
    search_text,
    favorites_only,
    grails_only,
    duplicates_only,
    has_photo_only,
    selected_category
  );
$$;

create or replace function public.library_search_collectible_category_counts(
  search_text text default null,
  favorites_only boolean default false,
  grails_only boolean default false,
  duplicates_only boolean default false,
  has_photo_only boolean default false
)
returns table(category text, item_count bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select c.category, count(*)::bigint as item_count
  from public.library_search_collectibles_base(
    search_text,
    favorites_only,
    grails_only,
    duplicates_only,
    has_photo_only,
    null
  ) c
  group by c.category
  order by count(*) desc, c.category asc;
$$;
