CREATE OR REPLACE PACKAGE BODY APPS.GCCEX053_PKG --合同BOM(成品/料件)
IS
   PROCEDURE main (
       errbuf           OUT   VARCHAR2,
       retcode          OUT   NUMBER,
       P_COP_EMS_NO     VARCHAR2, --企業內部編碼
       P_CONTRACT_NO_S  VARCHAR2, --合同號
       P_CONTRACT_NO_E  VARCHAR2, --合同號
       P_FG_ITEM_ID     NUMBER,  --成品ID
       P_ITEM_ID        NUMBER,  --料件ID
       P_G_MARK         VARCHAR2, --成品或料件
       P_FG_EMS_G_NO_S  NUMBER,   --成品序號(起) 2026/10/06 add
       P_FG_EMS_G_NO_E  NUMBER    --成品序號(迄) 2026/10/06 add
   )





    IS
      p_pre_item_id   NUMBER           := 0;
      p_e_stock_qty   NUMBER;
      p_c_stock_qty   NUMBER;
      V_BEGIN_DATE DATE;
      V_END_DATE   DATE;
      
       CURSOR C_EMS IS

       SELECT EXP_CONTRACT_NO, BEGIN_DATE, END_DATE, F_COP_EMS_NO
        FROM GCC_TR_MAS MAS
       WHERE COP_EMS_NO = P_COP_EMS_NO
         and ems_type = 'H'
         AND EXP_CONTRACT_NO >=  NVL(P_CONTRACT_NO_S, EXP_CONTRACT_NO)
         AND EXP_CONTRACT_NO <=  NVL(P_CONTRACT_NO_E, EXP_CONTRACT_NO)
         --AND MAS.END_DATE >= decode(P_ACTIVE_F,'Y',SYSDATE, '01-Jan-2000')  -- 2.增加條件Y(只抓生效的)
       ORDER BY EXP_CONTRACT_NO;
      

      CURSOR HZ_EXG (P_IMP_CONTRACT_NO varchar2) 
      IS
        SELECT FHE.IMP_CONTRACT_NO,
          FHE.COP_EMS_NO,
          FHE.EMS_G_NO,
          FHE.BOM_PERIOD,
          FHE.INVENTORY_ITEM_ID,
          FHE.CONCATENATED_SEGMENTS,
          FHE.ORGANIZATION_ID,
          FHE.ORGANIZATION_CODE,
         -- FHE.TRN_QTY,
          FHE.G_NO,
          FHE.QP_CODE,
          FHE.HS_CODE,
          FHE.G_NAME,
          FHE.G_MODEL,
          FHE.TRADE_MODE,
          FHE.GCC_UNIT,
          FHE.DEC_FACTOR,
          FHE.ERP_UNIT,
          FHE.UNIT_WEIGHT,
          FHE.DEC_PRICE,
         -- FHE.DEC_TOTAL,
          FHE.CUST_NAME,
          FHE.DEPARTMENT_NO,
          FHE.CUST_MENO,
          FHE.NOTE,
          FHE.TRN_QTY,
          FHE.DEC_TOTAL,
           decode(FHE.Attribute1,'2','加簽','3','連絡單','') Attribute1
        --  sum( FHE.TRN_QTY) TRN_QTY,
         -- sum( FHE.DEC_TOTAL) DEC_TOTAL
        FROM FL_GCC_HZ_EXG_ITEM  FHE
        WHERE FHE.COP_EMS_NO= NVL(P_COP_EMS_NO, FHE.COP_EMS_NO)
        AND FHE.imp_contract_no = NVL(P_IMP_CONTRACT_NO, FHE.imp_contract_no)
       -- AND FHE.IMP_CONTRACT_NO <= NVL(P_CONTRACT_NO_E, FHE.IMP_CONTRACT_NO)
        AND FHE.INVENTORY_ITEM_ID=NVL(P_FG_ITEM_ID, FHE.INVENTORY_ITEM_ID) 
        AND (P_FG_EMS_G_NO_S IS NULL OR FHE.EMS_G_NO >= P_FG_EMS_G_NO_S) --成品序號(起) 2026/10/06 add
        AND (P_FG_EMS_G_NO_E IS NULL OR FHE.EMS_G_NO <= P_FG_EMS_G_NO_E) --成品序號(迄) 2026/10/06 add
        order by FHE.imp_contract_no;
       
       

      CURSOR HZ_IMG (P_IMP_CONTRACT_NO varchar2)
      IS
        SELECT FHI.IMP_CONTRACT_NO,
          FHI.COP_EMS_NO,
          FHI.FG_EMS_G_NO,
          FHI.FG_TRN_QTY,
          FHI.FG_ITEM_NO,
          FHI.FG_ITEM_ID,
          FHI.EMS_G_NO,
          FHI.INVENTORY_ITEM_ID,
          FHI.CONCATENATED_SEGMENTS,
          FHI.EPR_UNIT,
          FHI.ORGANIZATION_CODE,
          FHI.ORGANIZATION_ID,
          FHI.DEC_PRICE,
          FHI.UNIT_WEIGHT,
          FHI.DEC_FACTOR,
          FHI.G_NO,
          FHI.HS_CODE,
          FHI.G_NAME,
          FHI.G_MODEL,
          FHI.GCC_UNIT,
          FHI.ERP_DEC_CM,
          FHI.GCC_DEC_CM,
          FHI.GCC_DEC_DM,
          FHI.TOTAL_DEC_DM,
          FHI.DEC_DM_QTY,
        --  FHI.TRN_QTY,
        --  FHI.DEC_TOTAL,
          FHI.TRADE_MODE,
          FHI.VEND_NAME,
          FHI.PACKING_FLAG,
          FHI.SUB_FLAG,
          FHI.NOTE,
         (FHI.TRN_QTY+ nvl(FHI.Add_Trn_Qty,0)) TRN_QTY,--備案+加簽數量
          FHI.DEC_TOTAL,
          decode(FHI.Attribute2,'2','加簽','3','連絡單','','1','加簽數量') Attribute2
        FROM FL_GCC_HZ_IMG_ITEM  FHI
        WHERE FHI.COP_EMS_NO= NVL(P_COP_EMS_NO, FHI.COP_EMS_NO)
        AND FHI.imp_contract_no= NVL(P_IMP_CONTRACT_NO, FHI.imp_contract_no)      
        AND FHI.INVENTORY_ITEM_ID=NVL(P_ITEM_ID, FHI.INVENTORY_ITEM_ID)
        --FG_EMS_G_NO 為 VARCHAR2，轉數字比較，非數字值視為 NULL 以免 ORA-01722
        AND (P_FG_EMS_G_NO_S IS NULL OR TO_NUMBER(CASE WHEN REGEXP_LIKE(TRIM(FHI.FG_EMS_G_NO), '^[0-9]+$') THEN TRIM(FHI.FG_EMS_G_NO) END) >= P_FG_EMS_G_NO_S) --成品序號(起) 2026/10/06 add
        AND (P_FG_EMS_G_NO_E IS NULL OR TO_NUMBER(CASE WHEN REGEXP_LIKE(TRIM(FHI.FG_EMS_G_NO), '^[0-9]+$') THEN TRIM(FHI.FG_EMS_G_NO) END) <= P_FG_EMS_G_NO_E) --成品序號(迄) 2026/10/06 add
        order by FHI.imp_contract_no;
       /* group   BY FHI.IMP_CONTRACT_NO,
          FHI.COP_EMS_NO,
          FHI.FG_EMS_G_NO,
          FHI.FG_TRN_QTY,
          FHI.FG_ITEM_NO,
          FHI.FG_ITEM_ID,
          FHI.EMS_G_NO,
          FHI.INVENTORY_ITEM_ID,
          FHI.CONCATENATED_SEGMENTS,
          FHI.EPR_UNIT,
          FHI.ORGANIZATION_CODE,
          FHI.ORGANIZATION_ID,
          FHI.DEC_PRICE,
          FHI.UNIT_WEIGHT,
          FHI.DEC_FACTOR,
          FHI.G_NO,
          FHI.HS_CODE,
          FHI.G_NAME,
          FHI.G_MODEL,
          FHI.GCC_UNIT,
          FHI.ERP_DEC_CM,
          FHI.GCC_DEC_CM,
          FHI.GCC_DEC_DM,
          FHI.TOTAL_DEC_DM,
          FHI.DEC_DM_QTY,
        --  FHI.TRN_QTY,
        --  FHI.DEC_TOTAL,
          FHI.TRADE_MODE,
          FHI.VEND_NAME,
          FHI.PACKING_FLAG,
          FHI.SUB_FLAG,
          FHI.NOTE;*/



        v_line          NUMBER;
        v_out_str       VARCHAR2 (32767);
        V_PARAMETER_PK_NO NUMBER;
        V_DUE_QTY              NUMBER;
        V_UOM_CONVERSIONS_RATE NUMBER;
        V_COP_FACTOR           NUMBER;
        V_G_DUE_QTY            NUMBER;
        V_UOM_CODE             VARCHAR2(3);
        V_DEC_UNIT             VARCHAR2(8);
        V_G_NO                 NUMBER;
        V_EMS_NO               VARCHAR2(20);



        BEGIN
          IF P_G_MARK = '4'                                               -- 成品
          THEN


             v_out_str := '|||||||合同BOM(成品明細表)(' || P_COP_EMS_NO || ')';
             fnd_file.put_line (fnd_file.output, v_out_str);
             v_out_str :=
                '企業內部編碼|合同號|成品序號|BOM版本|成品料號|組織|成品申請數量|憑證號|QP_CODE|HS_CODE|商品名稱|商品/規格型號|報關方式|合同單位|'; --20110908 add by jiayu 料件屬性
             v_out_str :=v_out_str||'比例因子|ERP單位|單重|單價 (USD)|總價 (USD)|客戶名稱|費用代碼|客戶備案信息|MESSAGES|是否加簽';
             fnd_file.put_line (fnd_file.output, v_out_str);

          for rec_ems in c_ems loop

             FOR R_HZ_EXG IN HZ_EXG (rec_ems.EXP_CONTRACT_NO) loop

               v_out_str := '"' || R_HZ_EXG.COP_EMS_NO || '"';--企業內部編碼
               v_out_str := v_out_str || '|"' || R_HZ_EXG.IMP_CONTRACT_NO || '"' ; --合同號


               v_out_str := v_out_str || '|"' || R_HZ_EXG.EMS_G_NO || '"' ;--成品序號
               v_out_str := v_out_str || '|"' || R_HZ_EXG.BOM_PERIOD || '"' ;--BOM版本
             --  v_out_str := v_out_str || '|"' || R_HZ_EXG.INVENTORY_ITEM_ID || '"' ;
               v_out_str := v_out_str || '|"' || R_HZ_EXG.CONCATENATED_SEGMENTS || '"' ; --成品料號
          --     v_out_str := v_out_str || '|"' || R_HZ_EXG.ORGANIZATION_ID || '"' ;
               v_out_str := v_out_str || '|"' || R_HZ_EXG.ORGANIZATION_CODE || '"' ;--組織
               v_out_str := v_out_str || '|"' || R_HZ_EXG.TRN_QTY || '"' ; --成品申請數量
               v_out_str := v_out_str || '|"' || R_HZ_EXG.G_NO || '"' ; --憑證號
               v_out_str := v_out_str || '|"' || R_HZ_EXG.QP_CODE || '"' ;--QP_CODE
               v_out_str := v_out_str || '|"' || R_HZ_EXG.HS_CODE || '"' ;--HS_CODE
               v_out_str := v_out_str || '|"' || R_HZ_EXG.G_NAME || '"' ;--商品名稱
               v_out_str := v_out_str || '|"' || R_HZ_EXG.G_MODEL || '"' ;--商品/規格型號
               v_out_str := v_out_str || '|"' || R_HZ_EXG.TRADE_MODE || '"' ;--報關方式
               v_out_str := v_out_str || '|"' || R_HZ_EXG.GCC_UNIT || '"' ;--合同單位
               v_out_str := v_out_str || '|"' || R_HZ_EXG.DEC_FACTOR || '"' ;--比例因子
               v_out_str := v_out_str || '|"' || R_HZ_EXG.ERP_UNIT || '"' ;--ERP單位
               v_out_str := v_out_str || '|"' || R_HZ_EXG.UNIT_WEIGHT || '"' ;--單重
               v_out_str := v_out_str || '|"' || R_HZ_EXG.DEC_PRICE || '"' ;--單價 (USD)
               v_out_str := v_out_str || '|"' || R_HZ_EXG.DEC_TOTAL || '"' ;--總價 (USD)
               v_out_str := v_out_str || '|"' || R_HZ_EXG.CUST_NAME || '"' ;--客戶名稱
               v_out_str := v_out_str || '|"' || R_HZ_EXG.DEPARTMENT_NO || '"' ;--費用代碼
               v_out_str := v_out_str || '|"' || R_HZ_EXG.CUST_MENO || '"' ;--客戶備案信息
               v_out_str := v_out_str || '|"' || R_HZ_EXG.NOTE || '"' ; --MESSAGES
               v_out_str := v_out_str || '|"' || R_HZ_EXG.Attribute1 || '"' ; --是否加簽
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, V_OUT_STR);

             END LOOP;
          --end if;
          --end;
          END LOOP;
          ELSIF P_G_MARK = '3'  -- 料件
          THEN


             v_out_str := '|||||||合同BOM(料件明細表)(' || P_COP_EMS_NO || ')';
             fnd_file.put_line (fnd_file.output, v_out_str);
             v_out_str :='企業內部編碼|手冊號|成品序號|成品數量|成品料號|料件序號|料件料號|ERP單位|料件ORG|料件單價(USD)|單重|';
             v_out_str := v_out_str || '比例因數|憑證號|HS_CODE|商品名稱|商品規格型號|合同單位|ERP單耗|合同單耗|損耗(百分比)|損耗量|總損耗|';
             v_out_str := v_out_str || '料件申請數量|總價(USD)|報關方式|廠商名稱|是否包材|替代料|MESSAGES|是否加簽';
             fnd_file.put_line (fnd_file.output, v_out_str);

             for rec_ems in c_ems loop
               FOR R_HZ_IMG IN HZ_IMG  (rec_ems.EXP_CONTRACT_NO) 
               LOOP

                  v_out_str := '"' ||  R_HZ_IMG.COP_EMS_NO || '"'; --企業內部編碼
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.IMP_CONTRACT_NO|| '"' ;--手冊號
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.FG_EMS_G_NO|| '"' ;--成品序號
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.FG_TRN_QTY|| '"' ;--成品數量
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.FG_ITEM_NO|| '"' ;--成品料號
              --    v_out_str := v_out_str || '|"' || R_HZ_IMG.FG_ITEM_ID|| '"' ;
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.EMS_G_NO|| '"' ;--料件序號
             --     v_out_str := v_out_str || '|"' || R_HZ_IMG.INVENTORY_ITEM_ID|| '"' ;
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.CONCATENATED_SEGMENTS|| '"' ;--料件料號
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.EPR_UNIT|| '"' ;--ERP單位
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.ORGANIZATION_CODE|| '"' ;--料件ORG
               --   v_out_str := v_out_str || '|"' || R_HZ_IMG.ORGANIZATION_ID|| '"' ;
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.DEC_PRICE|| '"' ;--料件單價(USD)
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.UNIT_WEIGHT|| '"' ;--單重
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.DEC_FACTOR|| '"' ;--比例因數
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.G_NO|| '"' ;--憑證號
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.HS_CODE|| '"' ;--HS_CODE
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.G_NAME|| '"' ;--商品名稱
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.G_MODEL|| '"' ;--商品規格型號
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.GCC_UNIT|| '"' ;--合同單位
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.ERP_DEC_CM|| '"' ;--ERP單耗
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.GCC_DEC_CM|| '"' ;--合同單耗
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.GCC_DEC_DM|| '"' ;--損耗(百分比)
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.DEC_DM_QTY|| '"' ;--損耗量
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.TOTAL_DEC_DM|| '"' ;--總損耗
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.TRN_QTY|| '"' ;--料件申請數量
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.DEC_TOTAL|| '"' ;--總價(USD)
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.TRADE_MODE|| '"' ;--報關方式
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.VEND_NAME|| '"' ;--廠商名稱
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.PACKING_FLAG|| '"' ;--是否包材
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.SUB_FLAG|| '"' ;--替代料
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.NOTE|| '"' ;--MESSAGES
                  v_out_str := v_out_str || '|"' || R_HZ_IMG.Attribute2 || '"' ; --是否加簽

                  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, V_OUT_STR);

               END LOOP;
             END LOOP;
          END IF;

      EXCEPTION
    WHEN OTHERS THEN
      ERRBUF  := SQLERRM;
      RETCODE := SQLCODE;
  END;

  END GCCEX053_PKG;
/

