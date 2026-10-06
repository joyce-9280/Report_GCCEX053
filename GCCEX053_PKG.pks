CREATE OR REPLACE PACKAGE APPS.GCCEX053_PKG IS

  -- AUTHOR  : jiayu.chen
  -- CREATED : 2018/02/05
  -- PURPOSE : 合同BOM
  --條件：企業內部編碼/合同號/成品ID/料件ID/成品或料件


  PROCEDURE MAIN(ERRBUF           OUT VARCHAR2,
                 RETCODE          OUT NUMBER,
                 P_COP_EMS_NO     VARCHAR2, --企業內部編碼
                 P_CONTRACT_NO_S  VARCHAR2, --合同號
                 P_CONTRACT_NO_E  VARCHAR2, --合同號
                 P_FG_ITEM_ID     NUMBER,  --成品ID
                 P_ITEM_ID        NUMBER,  --料件ID
                 P_G_MARK         VARCHAR2  --成品或料件
);



END GCCEX053_PKG;
/

