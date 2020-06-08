

  SELECT animenameromaji AS name, grpshortname AS 'group', eps,
         animeeptotal AS total,
         (CASE
              WHEN eps = animeeptotal THEN 'complete'
              WHEN eps < animeeptotal THEN 'ongoing'
              WHEN eps > animeeptotal AND animeeptotal > 0 THEN 'WHAT'
              WHEN eps > animeeptotal AND animeeptotal = 0 THEN 'ongoing'
          END) AS status
    FROM anime a, grp g,
         (  SELECT m.animeid AS animeid, m.grpid AS grpid,
                   count(DISTINCT e.epsequence) AS eps
              FROM mediafile m, episode e
             WHERE e.epid = m.epid
                   AND e.animeid = m.animeid
                   AND e.epsequence NOT LIKE '%s%'
          GROUP BY m.animeid, m.grpid
         ) stats
   WHERE a.animeid = stats.animeid
         AND g.grpid = stats.grpid
ORDER BY name;


