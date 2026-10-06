CREATE OR REPLACE PACKAGE APPS.GCCEX053_PKG IS

  -- AUTHOR  : jiayu.chen
  -- CREATED : 2018/02/05
  -- PURPOSE : 合同BOM
  --條件：企業內部編碼/合同號/成品ID/料件ID/成品或料件/成品序號(起迄)
  -- 2026/10/06 增加參數 成品序號(起)、成品序號(迄)


  PROCEDURE MAIN(ERRBUF           OUT VARCHAR2,
                 RETCODE          OUT NUMBER,
                 P_COP_EMS_NO     VARCHAR2, --企業內部編碼
                 P_CONTRACT_NO_S  VARCHAR2, --合同號
                 P_CONTRACT_NO_E  VARCHAR2, --合同號
                 P_FG_ITEM_ID     NUMBER,  --成品ID
                 P_ITEM_ID        NUMBER,  --料件ID
                 P_G_MARK         VARCHAR2, --成品或料件
                 P_FG_EMS_G_NO_S  NUMBER,   --成品序號(起) 2026/10/06 add
                 P_FG_EMS_G_NO_E  NUMBER    --成品序號(迄) 2026/10/06 add
);



END GCCEX053_PKG;
/

