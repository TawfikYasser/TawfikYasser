SELECT COUNT(*) FROM (
    SELECT hash_prep.*,
        CASE WHEN HASH_PREP.HASH_KEY = FIRST_VALUE(HASH_PREP.HASH_KEY) OVER(
            PARTITION BY HASH_PREP.ctry_key, HASH_PREP.ctry_ISO_key ORDER BY HASH_PREP.strt_dt ASC
            ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING)
        THEN 1 ELSE 0 END AS FK_UP
    FROM (
        SELECT BUS_QRY.*,
            sha2(
coalesce(ctry_nm, '') ||
coalesce(ctry_arbc_nm, '') ||
coalesce(contnt, '') ||
coalesce(ctry_dial_cd, '') ||
coalesce(ctry_flg, '') ||
coalesce(embsy_nm, '') ||
coalesce(embsy_arbc_nm, '')
            , 256) AS HASH_KEY
        FROM (
            select
            atos_iso2 ctry_key, --PK
            atos_isonum ctry_ISO_key, 
            atos_name ctry_nm,
            atos_arabicname ctry_arbc_nm,
            CASE
            
            -- Africa
            WHEN LOWER(atos_name) IN (
            'algeria','angola','benin','botswana','burkina faso','burundi',
            'cabo verde','cameroon','central african republic','chad','comoros',
            'congo (congo-brazzaville)','democratic republic of the congo',
            'côte d’ivoire','djibouti','egypt','equatorial guinea','eritrea',
            'eswatini (fmr. “swaziland”)','ethiopia','gabon','gambia','ghana',
            'guinea','guinea-bissau','kenya','lesotho','liberia','libya',
            'madagascar','malawi','mali','mauritania','mauritius','morocco',
            'mozambique','namibia','niger','nigeria','rwanda',
            'sao tome and principe','senegal','seychelles','sierra leone',
            'somalia','south africa','south sudan','sudan','tanzania',
            'togo','tunisia','uganda','western sahara','zambia','zimbabwe',
            'ascension island'
            ) THEN 'Africa'
            
            -- Asia
            WHEN LOWER(atos_name) IN (
            'afghanistan','armenia','azerbaijan','bahrain','bangladesh','bhutan',
            'brunei','cambodia','china','china mainland','georgia','hong kong',
            'india','indonesia','iran','iraq','israel','japan','jordan',
            'kazakhstan','kuwait','kyrgyzstan','laos','lebanon','macao',
            'malaysia','maldives','mongolia','myanmar (formerly burma)',
            'myanmar [burma]','nepal','north korea','oman','pakistan',
            'palestine state','philippines','qatar','saudi arabia',
            'singapore','south korea','sri lanka','syria','tajikistan',
            'thailand','timor-leste','turkmenistan','united arab emirates',
            'uzbekistan','vietnam','yemen','chagos archipelago','turkey'
            ) THEN 'Asia'
            
            -- Europe
            WHEN LOWER(atos_name) IN (
            'albania','andorra','austria','belarus','belgium','bosnia and herzegovina',
            'bulgaria','croatia','cyprus','czechia (czech republic)','denmark',
            'estonia','faroe islands','finland','france','germany','gibraltar',
            'greece','guernsey','holy see','hungary','iceland','ireland',
            'isle of man','italy','jersey','latvia','liechtenstein','lithuania',
            'luxembourg','malta','moldova','monaco','montenegro','netherlands',
            'north macedonia','norway','poland','portugal','romania','russia',
            'san marino','serbia','slovakia','slovenia','spain','sweden',
            'switzerland','ukraine','united kingdom','åland islands'
            ) THEN 'Europe'
            
            -- North America
            WHEN LOWER(atos_name) IN (
            'anguilla','antigua and barbuda','aruba','bahamas','barbados',
            'belize','bermuda','canada','caribbean netherlands','cayman islands',
            'costa rica','cuba','curaçao','dominica','dominican republic',
            'el salvador','greenland','grenada','guadeloupe','guatemala',
            'haiti','honduras','jamaica','martinique','mexico','nicaragua',
            'panama','saint lucia','saint vincent and the grenadines',
            'st. kitts & nevis','st. martin','trinidad and tobago',
            'united states of america','st. barthélemy',
            'st. lucia'
            ) THEN 'North America'
            
            -- South America
            WHEN LOWER(atos_name) IN (
            'argentina','bolivia','brazil','chile','colombia','ecuador',
            'falkland islands','french guiana','guyana','paraguay',
            'peru','suriname','uruguay','venezuela'
            ) THEN 'South America'
            
            -- Oceania
            WHEN LOWER(atos_name) IN (
            'american samoa','australia','christmas island','cocos [keeling] islands',
            'cook islands','fiji','kiribati','marshall islands','micronesia',
            'nauru','new zealand','niue','norfolk island','northern mariana islands',
            'palau','papua new guinea','samoa','solomon islands','tonga',
            'tuvalu','vanuatu','guam'
            ) THEN 'Oceania'
            
            ELSE 'Others'
            
            END AS contnt,
            atos_countrycode ctry_dial_cd,
            atos_flag ctry_flg,
            atos_embassyenglishname embsy_nm,
            atos_embassyarabicname embsy_arbc_nm,
            strt_dt
            
            
            from 
            
            (
            
                    select * ,
            	 CASE 
                        WHEN ROW_NUMBER() OVER (PARTITION BY ATOS_COuntryid ORDER BY ts_ms ASC) = 1 
                         THEN CAST(from_unixtime(CAST(CreatedOn AS BIGINT) DIV 1000) AS date)
                        ELSE CAST(from_unixtime(CAST(modifiedon AS BIGINT) DIV 1000) AS date)
                    END AS strt_dt,
            	ROW_NUMBER() OVER (PARTITION BY ATOS_COuntryid ORDER BY ts_ms desc) AS RNK
            
            	from stg_crm.atos_countrybase
            )ctry
            where ctry.rnk = 1
        ) BUS_QRY
    ) HASH_PREP
) FINAL WHERE FK_UP <> 1
