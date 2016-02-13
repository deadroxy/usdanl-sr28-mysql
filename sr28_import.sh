#!/bin/bash

# first download and unzip USDA National Nutrient Database (Release SR-28) ASCII version
wget https://www.ars.usda.gov/SP2UserFiles/Place/12354500/Data/SR/SR28/dnload/sr28asc.zip
unzip ./sr28asc.zip

# transform all data files from DOS to UNIX file format
for textfile in *.txt
do
  echo "Converting $textfile"
  iconv -f CP1252 -t UTF-8 $textfile | dos2unix > temp.txt
  mv temp.txt $textfile
done  
    
# set MySQL variables used for later database management operations
MYSQL_USR=$1

# create database with predefined schema
mysql -u${MYSQL_USR} < ./sr28_schema.sql &&

HOME=`pwd`;
# import USDA SR-28 data files into predefined table schema
# some queries must handle fact that dataset has absent values without specifying nulls
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/FD_GROUP.txt' INTO TABLE FD_GROUP FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/FOOD_DES.txt' INTO TABLE FOOD_DES FIELDS TERMINATED BY '^' ENCLOSED BY '\~' (NDB_No, FdGrp_Cd, Long_Desc, Shrt_Desc, ComName, ManufacName, Survey, Ref_desc, @vRefuse, SciName, @N_Factor, @vPro_Factor, @vFat_Factor, @vCHO_Factor) SET Refuse = nullif(@vRefuse,''), N_Factor = nullif(@vN_Factor,''), Pro_Factor = nullif(@vPro_Factor,''), Fat_Factor = nullif(@vFat_Factor,''), CHO_Factor = nullif(@vCHO_Factor,'');;" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/DATA_SRC.txt' INTO TABLE DATA_SRC FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/DERIV_CD.txt' INTO TABLE DERIV_CD FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/FOOTNOTE.txt' INTO TABLE FOOTNOTE FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/LANGDESC.txt' INTO TABLE LANGDESC FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/WEIGHT.txt' INTO TABLE WEIGHT FIELDS TERMINATED BY '^' ENCLOSED BY '\~' (NDB_No, Seq, Amount, Msre_Desc, Gm_Wgt, @vNum_Data_Pts, @vStd_Dev) SET Num_Data_Pts = nullif(@vNum_Data_Pts,''), Std_Dev = nullif(@vStd_Dev,'');" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/NUTR_DEF.txt' INTO TABLE NUTR_DEF FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/LANGUAL.txt' INTO TABLE LANGUAL FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/SRC_CD.txt' INTO TABLE SRC_CD FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/DATSRCLN.txt' INTO TABLE DATSRCLN FIELDS TERMINATED BY '^' ENCLOSED BY '\~';" &&
mysql -u${MYSQL_USR} -e "USE usdanlsr28; LOAD DATA INFILE '${HOME}/NUT_DATA.txt' INTO TABLE NUT_DATA FIELDS TERMINATED BY '^' ENCLOSED BY '\~' (NDB_No, Nutr_No, Nutr_Val, Num_Data_Pts, @Std_Error, Src_Cd, Deriv_Cd, Ref_NDB_No, Add_Nutr_Mark, @vNum_Studies, @vMin, @vMax, @vDF, @vLow_EB, @vUp_EB, Stat_cmt, AddMod_Date, CC) SET Std_Error = nullif(@vStd_Error,''), Num_Studies = nullif(@vNum_Studies,''), Min = nullif(@vMin,''), Max = nullif(@vMax,''), DF = nullif(@vDF,''), Low_EB = nullif(@vLow_EB,''), Up_EB = nullif(@vUp_EB,'');" &&

echo "USDA National Nutrient Database imported successfully"
rm *.txt *.zip *.pdf
echo "Clean up complete."

# run test query
# mysql -u${MYSQL_USR} -e "USE usdanlsr28;select * from NUT_DATA;"
