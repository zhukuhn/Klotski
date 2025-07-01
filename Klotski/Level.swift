//
//  Level.swift
//  Klotski
//
//  Created by zhukun on 2025/6/15.
//
import Foundation

struct ClassicLevels {

    static let allClassicLevels: [Level] = [
        hengDaoLiMa,
        biYiHengKong,
        jieZuXianDeng,
        qiaoGuoWuGuan,
        bingLinCaoYing,
        yiLuShunFeng,
        wuHuLanLu,
        duSeYaoDao,
        qianDangHouDu,
        yuShengXiLi,
        bingLinChengXia,
        yiLuJinJun,
        qiTouBingJin,
        chaChiNanFei,
        sanJunLianFang,
        weiErBuJian,
        siLuJieBing,
        taoHuaYuanZhong,
        jiangShouJiaoLou,
        tunBingDongLu,
        jiangYongCaoYing,
        bingFenSanLu,
        bingJiangLianHuan,
        shuiXieBuTong,
        hengShuJieJiang,
        shouKouRuPingOne,
        hengMaDangGuan,
        bingDangJiangZu,
        shouKouRuPingTwo,
        cengCengSheFangOne,
        cengCengSheFangTwo,
        fengHuiLuZhuan,
    ]

    // MARK: - Level Definitions (Final Corrected Version)

    static let hengDaoLiMa = Level(
        id: "heng_dao_li_ma",
        name: "横刀立马",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),       // 曹操
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let biYiHengKong = Level(
        id: "bi_yi_heng_kong",
        name: "比翼横空",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 2, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiH, initialX: 0, initialY: 0),
            PiecePlacement(id: 2, type: .zhaoYunH, initialX: 0, initialY: 1),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 2, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoH, initialX: 0, initialY: 2),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 4)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let jieZuXianDeng = Level(
        id: "jie_zu_xian_deng",
        name: "捷足先登",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 2, type: .maChaoV, initialX: 0, initialY: 3),
            PiecePlacement(id: 3, type: .huangZhongV, initialX: 1, initialY: 3),
            PiecePlacement(id: 4, type: .zhaoYunV, initialX: 2, initialY: 3),
            PiecePlacement(id: 5, type: .zhangFeiV, initialX: 3, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let qiaoGuoWuGuan = Level(
        id: "qiao_guo_wu_guan",
        name: "巧过五关",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiH, initialX: 0, initialY: 2),
            PiecePlacement(id: 2, type: .zhaoYunH, initialX: 0, initialY: 3),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 4),
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 1),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let bingLinCaoYing = Level(
        id: "bing_lin_cao_ying",
        name: "兵临曹营",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 3),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 3),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let yiLuShunFeng = Level(
        id: "yi_lu_shun_feng",
        name: "一路顺风",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 3),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 4),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let wuHuLanLu = Level(
        id: "wu_hu_lan_lu",
        name: "五虎拦路",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 2, initialY: 0),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 1),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 2, initialY: 2),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let duSeYaoDao = Level(
        id: "du_se_yao_dao",
        name: "堵塞要道",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 2, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let qianDangHouDu = Level(
        id: "qian_dang_hou_du",
        name: "前挡后堵",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 0),     // 横将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 1),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let yuShengXiLi = Level(
        id: "yu_sheng_xi_li",
        name: "雨声淅沥",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 横将
            PiecePlacement(id: 3, type: .maChaoV, initialX: 0, initialY: 2),       // 横将
            PiecePlacement(id: 4, type: .huangZhongV, initialX: 1, initialY: 3),   // 横将
            PiecePlacement(id: 5, type: .zhaoYunV, initialX: 3, initialY: 2),      // 横将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 1),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let bingLinChengXia = Level(
        id: "bing_lin_cheng_xia",
        name: "兵临城下",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 1)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let yiLuJinJun = Level(
        id: "yi_lu_jin_jun",
        name: "一路进军",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let qiTouBingJin = Level(
        id: "qi_tou_bing_jin",
        name: "齐头并进",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 3),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let chaChiNanFei = Level(
        id: "cha_chi_nan_fei",
        name: "插翅难飞",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 0, initialY: 2),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 0, initialY: 3),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let sanJunLianFang = Level(
        id: "san_jun_lian_fang",
        name: "三军联防",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 2, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 3),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let weiErBuJian = Level(
        id: "wei_er_bu_jian",
        name: "围而不歼",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 0, initialY: 2),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 0, initialY: 0),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let siLuJieBing = Level(
        id: "si_lu_jie_bing",
        name: "四路皆兵",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 3),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 3),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunH, initialX: 0, initialY: 4),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 4),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 2),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let taoHuaYuanZhong = Level(
        id: "tao_hua_yuan_zhong",
        name: "桃花源中",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 0, initialY: 1),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 3, initialY: 1),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 4),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 1, initialY: 2),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 2, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
            
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let jiangShouJiaoLou = Level(
        id: "jiang_shou_jiao_lou",
        name: "将守角楼",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 0, initialY: 0),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 1, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 2)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let tunBingDongLu = Level(
        id: "tun_bing_dong_lu",
        name: "屯兵东路",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .zhangFeiV, initialX: 2, initialY: 0),
            PiecePlacement(id: 2, type: .zhaoYunV, initialX: 3, initialY: 0),
            PiecePlacement(id: 3, type: .guanYuH, initialX: 0, initialY: 2),
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 3),
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let jiangYongCaoYing = Level(
        id: "jiang_yong_cao_ying",
        name: "将拥曹营",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 4),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 1),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 2),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 2),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 1),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let bingFenSanLu = Level(
        id: "bing_fen_san_lu",
        name: "兵分三路",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 1),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 1),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 3),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 3)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let bingJiangLianHuan = Level(
        id: "bing_jiang_lian_huan",
        name: "兵将连环",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 0, initialY: 3),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunH, initialX: 2, initialY: 2),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 1),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let shuiXieBuTong = Level(
        id: "shui_xie_bu_tong",
        name: "水泄不通",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),       // 曹操 (红)
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将 (米)
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 2),     // 竖将 (米)
            PiecePlacement(id: 3, type: .zhaoYunH, initialX: 0, initialY: 3),      // 竖将 (米)
            PiecePlacement(id: 4, type: .maChaoH, initialX: 2, initialY: 3),       // 竖将 (米)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 0, initialY: 0),   // 竖将 (米)
            PiecePlacement(id: 6, type: .soldier, initialX: 3, initialY: 0),       // 士兵 (黑)
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 1),       // 士兵 (黑)
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),       // 士兵 (黑)
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 (黑)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let hengShuJieJiang = Level(
        id: "heng_shu_jie_jiang",
        name: "横竖皆将",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将 
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 横将 
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将 
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将 
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 0, initialY: 2),   // 竖将 
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),       // 士兵 
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 2),       // 士兵 
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵 
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 士兵 
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )  

    static let shouKouRuPingOne = Level(
        id: "shou_kou_ru_ping_one",
        name: "守口如瓶之一",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 4),     // 横将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵 
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let hengMaDangGuan = Level(
        id: "heng_ma_dang_guan",
        name: "横马当关",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 2),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 3),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 4),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 3),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let bingDangJiangZu = Level(
        id: "bing_dang_jiang_zu",
        name: "兵挡将阻",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 2),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 1),        // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let shouKouRuPingTwo = Level(
        id: "shou_kou_ru_ping_two",
        name: "守口如瓶之二",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 4),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 2, initialY: 4),     // 横将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 1),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 1),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 2),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let cengCengSheFangOne = Level(
        id: "ceng_ceng_she_fang_one",
        name: "层层设防之一",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 0),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 0),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 2),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let cengCengSheFangTwo = Level(
        id: "ceng_ceng_she_fang_two",
        name: "层层设防之二",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),      // 横将
            PiecePlacement(id: 2, type: .zhangFeiH, initialX: 1, initialY: 3),     // 竖将
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 0, initialY: 1),      // 竖将
            PiecePlacement(id: 4, type: .maChaoV, initialX: 3, initialY: 1),       // 竖将
            PiecePlacement(id: 5, type: .huangZhongH, initialX: 1, initialY: 4),   // 竖将
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),       // 士兵
            PiecePlacement(id: 7, type: .soldier, initialX: 0, initialY: 3),       // 士兵
            PiecePlacement(id: 8, type: .soldier, initialX: 3, initialY: 0),       // 士兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)        // 士兵
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )

    static let fengHuiLuZhuan = Level(
        id: "feng_hui_lu_zhuan",
        name: "峰回路转",
        boardWidth: 4, boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 1),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 2, initialY: 1),
            PiecePlacement(id: 3, type: .maChaoV, initialX: 3, initialY: 0),
            PiecePlacement(id: 4, type: .zhaoYunH, initialX: 2, initialY: 4),
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 0),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 0),
            PiecePlacement(id: 9, type: .soldier, initialX: 1, initialY: 4)
        ],
        targetPieceId: 0, targetX: 1, targetY: 3
    )
}
