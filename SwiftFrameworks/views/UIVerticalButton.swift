//
//  UIVerticalButton.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/10/25.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class UIVerticalButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = titleLabel!.sizeThatFits(bounds.size)
        let imageHeight = bounds.height - size.height
        titleLabel!.textAlignment = NSTextAlignment.Center
        titleLabel!.frame = CGRect(x: 0, y: imageHeight, width: bounds.width, height: size.height)
        imageView!.contentMode = .Center
        imageView!.frame = CGRect(x: 0, y: 0, width: bounds.width, height: imageHeight)
    }

}
