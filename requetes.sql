-- requetes.sql
-- Par Guillaume Lahaie
-- LAHG04077707
-- Remise: 14 novembre 2012 

SET ECHO ON
SPOOL requetes.out

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'
/
-- 1. Les numéros des articles (sans répétition) qui ont été commandés au moins
--    une fois.
SELECT DISTINCT noArticle
FROM lignecommande
/

-- 2. Le numéro et la description des articles dont le numéro est supérieur à
--    45 et dont la description débute par 'Po' ou contient la lettre 'a'.
SELECT noArticle, description
FROM Article
WHERE (noArticle > 45) 
AND ((description LIKE 'Po%') OR (description LIKE '%a%'))
/

-- 3. Le numéro et la description des articles 10, 40 et 80.
SELECT noArticle, description
FROM Article
WHERE noArticle IN (10,40,80)
/

-- 4. Le nom du client de la commande 7.
SELECT nomClient
FROM Client NATURAL JOIN Commande
WHERE Commande.noCommande = 7
/

-- 5. Les noms des clients (sans répétition) qui ont une livraison datée du 
--    4 juin ou du 9 juillet 2000.
SELECT DISTINCT nomClient
FROM Client NATURAL JOIN Commande NATURAL JOIN DetailLivraison
     NATURAL JOIN Livraison
WHERE dateLivraison = '2000-06-04' OR dateLivraison = '2000-07-09'
/

-- 6. La liste des dates pour lesquelles il y a au moins une livraison ou une
--    commande. Les résultats sont produits en une colonne nommée 
--    DateÉvénement
( SELECT dateCommande AS dateÉvènement
  FROM commande
)
UNION
( SELECT dateLivraison AS dateÉvènement
  FROM Livraison
)
/

-- 7. En deux colonnes, donner les noArticle et la quantité totale commandée
--    de l'article incluant les articles dont la quantité totale commandée est
--    égale à 0.
SELECT noArticle,
  CASE
    WHEN SUM(quantite) IS NULL THEN 0
    ELSE SUM(quantite)
  END AS "QUANTITE COMMANDEE"
FROM Article NATURAL LEFT OUTER JOIN LigneCommande
GROUP BY noArticle
/

-- 8. En deux colonnes, donner les noArticle et la quantité totale commandée
--    de l'article incluant les articles dont la quantité totale commandée est
--    égale à 0, et uniquement pour les articles dont le noArticle est 
--    inférieure à 70 et la quantité totale commandée est inférieure à 5.
SELECT noArticle,
  CASE
    WHEN SUM(quantite) IS NULL THEN 0
    ELSE SUM(quantite)
  END AS "QUANTITE COMMANDEE"
FROM Article NATURAL LEFT OUTER JOIN LigneCommande
GROUP BY noArticle
HAVING noArticle < 70 AND (SUM(quantite) <5 OR SUM(quantite) IS NULL)
/

-- 9. Le noLivraison, noCommande, noArticle, la date de commande, la quantité
--    commandée, la date de livraison, la quantité livrée et le nombre de jours
--    écoulés entre la commande et la livraison dans le cas où ce nombre a 
--    dépassé 2 jours et le nombre de jours écoulés depuis la commande jusqu'à
--    aujourd'hui est supérieur à 100.
SELECT noLivraison, noCommande, noArticle, dateCommande, quantite, 
       dateLivraison, quantiteLivree, (dateLivraison - dateCommande) AS 
       Nombre_jours_ecoules
FROM Commande NATURAL JOIN LigneCommande NATURAL JOIN DetailLivraison
     NATURAL JOIN Livraison
WHERE (dateLivraison - dateCommande) > 2 AND (SYSDATE - dateCommande) > 100
/

-- 10. La table DétailLivraison triée en ordre décroissant de noCommande et pour
--     chaque noCommande, en ordre croissant de quantitéLivrée.
SELECT *
FROM DetailLivraison
ORDER BY noCommande DESC, quantiteLivree ASC
/

-- 11. Le nombre d'article dont la quantité totale commandée est supérieure à
--     5 et le nombre d'articles dont la quantité totale commandée est
--     inférieure à 2 (en deux colonnes). 
SELECT *
FROM
  (( SELECT COUNT(*) NombrePopulaires
     FROM (
        SELECT noArticle
        FROM LigneCommande
        GROUP BY noArticle
        HAVING SUM(quantite) > 5
     )   
    )
    CROSS JOIN
    ( SELECT COUNT(*) AS NombreImpopulaires
      FROM
        ( SELECT noArticle
          FROM Article NATURAL LEFT OUTER JOIN LigneCommande
          GROUP BY noArticle
          HAVING SUM(quantite) < 2 OR SUM(quantite) IS NULL
        )
    )
)
/

-- 12. Les noArticle des articles qui n'ont jamais été commandés.
SELECT noArticle
FROM Article NATURAL LEFT OUTER JOIN LigneCommande
GROUP BY noArticle
HAVING SUM(quantite) IS NULL
/

-- 13. Le noLivraison des dernières livraisons (i.e. celles dont la date de
--     livraison est la plus récente).
SELECT noLivraison
FROM Livraison
WHERE dateLivraison IN
  ( SELECT MAX(dateLivraison) AS dateMax
    FROM Livraison
  )
/

-- 14. Le montant total commandé pour chaque paire (noClient, noArticle) dans
--     les cas où le montant dépasse 50$.
SELECT noClient, noArticle, 
       SUM(quantite*prixUnitaire) AS "Montant Total Commande"
FROM Commande NATURAL JOIN LigneCommande NATURAL JOIN Article
GROUP BY noClient, noArticle
HAVING SUM(quantite*prixUnitaire) > 50
/

-- 15. Les noLivraison des livraisons qui touchent à toutes et chacune des
--     commandes du client 10 faites au mois de juin 2000.
SELECT DISTINCT noLivraison
FROM DetailLivraison
WHERE NOT EXISTS
  (( SELECT noCommande
     FROM Commande
     WHERE noClient = 10 
     AND (dateCommande BETWEEN '2000-06-01' AND '2000-06-30')
   )
   MINUS
   ( SELECT noCommande
     FROM DetailLivraison D
     WHERE D.noLivraison = DetailLivraison.noLivraison
   )
  )
/ 

SET ECHO OFF
SPOOL OFF
