//
//  Level.swift
//  Klotski
//
//  Created by zhukun on 2025/6/15.
//
import Foundation

struct ClassicLevels {
    
    // An array containing all predefined classic Klotski levels.
    // 您可以将此数组用于游戏中的关卡选择界面。
    static let allClassicLevels: [Level] = [
        hengDaoLiMa,
        jiangShouYuanMen,
        cunBingDongLu,
        cengCengSheFang,
        chaChiNanFei,
        bingLinChengXia,
        guanDuZhiZhan,
        shuiXieBuTong,
        guoWuGuan,
        xiaoYanChuChao,
        fengHuiLuZhuan,
        chiBiZhiZhan
    ]
    
    // MARK: - Level Definitions

    // 1. 横刀立马 (Héng Dāo Lì Mǎ)
    static let hengDaoLiMa = Level(
        id: "classic-heng-dao-li-ma",
        name: "横刀立马",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),       // 曹操
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 3),       // 兵
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),       // 兵
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),       // 兵
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)        // 兵
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 2. 将守辕门 (Jiàng Shǒu Yuán Mén)
    static let jiangShouYuanMen = Level(
        id: "classic-jiang-shou-yuan-men",
        name: "将守辕门",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 3. 屯兵东路 (Tún Bīng Dōng Lù)
    static let cunBingDongLu = Level(
        id: "classic-cun-bing-dong-lu",
        name: "屯兵东路",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 2, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 0, initialY: 0),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 1),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 1),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 1, initialY: 3),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 3)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )
    
    // 4. 层层设防 (Céng Céng Shè Fáng)
    static let cengCengSheFang = Level(
        id: "classic-ceng-ceng-she-fang",
        name: "层层设防",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 3)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )
    
    // 5. 插翅难飞 (Chā Chì Nán Fēi)
    static let chaChiNanFei = Level(
        id: "classic-cha-chi-nan-fei",
        name: "插翅难飞",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 1),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 0),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )
    
    // 6. 兵临城下 (Bīng Lín Chéng Xià)
    static let bingLinChengXia = Level(
        id: "classic-bing-lin-cheng-xia",
        name: "兵临城下",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 2),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 2),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 0),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 0),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )
    
    // 7. 官渡之战 (Guān Dù Zhī Zhàn)
    static let guanDuZhiZhan = Level(
        id: "classic-guan-du-zhi-zhan",
        name: "官渡之战",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 8. 水泄不通 (Shuǐ Xiè Bù Tōng)
    static let shuiXieBuTong = Level(
        id: "classic-shui-xie-bu-tong",
        name: "水泄不通",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 1),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 0),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 0),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 9. 过五关 (Guò Wǔ Guān)
    static let guoWuGuan = Level(
        id: "classic-guo-wu-guan",
        name: "过五关",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 3),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 3),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 3, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 9, type: .soldier, initialX: 2, initialY: 3)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 10. 小燕出巢 (Xiǎo Yàn Chū Cháo)
    static let xiaoYanChuChao = Level(
        id: "classic-xiao-yan-chu-chao",
        name: "小燕出巢",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 3),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 2),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 2),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 11. 峰回路转 (Fēng Huí Lù Zhuǎn)
    static let fengHuiLuZhuan = Level(
        id: "classic-feng-hui-lu-zhuan",
        name: "峰回路转",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 1, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 1, initialY: 2),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 0),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 3, initialY: 0),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 0, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 1, initialY: 3),
            PiecePlacement(id: 7, type: .soldier, initialX: 2, initialY: 3),
            PiecePlacement(id: 8, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )

    // 12. 赤壁之战 (Chì Bì Zhī Zhàn)
    static let chiBiZhiZhan = Level(
        id: "classic-chi-bi-zhi-zhan",
        name: "赤壁之战",
        boardWidth: 4,
        boardHeight: 5,
        piecePlacements: [
            PiecePlacement(id: 0, type: .caoCao, initialX: 0, initialY: 0),
            PiecePlacement(id: 1, type: .guanYuH, initialX: 2, initialY: 0),       // 关羽 (横)
            PiecePlacement(id: 2, type: .zhangFeiV, initialX: 0, initialY: 2),     // 张飞 (竖)
            PiecePlacement(id: 3, type: .zhaoYunV, initialX: 1, initialY: 2),      // 赵云 (竖)
            PiecePlacement(id: 4, type: .maChaoV, initialX: 2, initialY: 2),       // 马超 (竖)
            PiecePlacement(id: 5, type: .huangZhongV, initialX: 3, initialY: 2),   // 黄忠 (竖)
            PiecePlacement(id: 6, type: .soldier, initialX: 0, initialY: 4),
            PiecePlacement(id: 7, type: .soldier, initialX: 1, initialY: 4),
            PiecePlacement(id: 8, type: .soldier, initialX: 2, initialY: 4),
            PiecePlacement(id: 9, type: .soldier, initialX: 3, initialY: 4)
        ],
        targetPieceId: 0,
        targetX: 1,
        targetY: 3
    )
}
