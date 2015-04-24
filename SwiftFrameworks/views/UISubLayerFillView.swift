//
//  UISubLayerFillView.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/11/4.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit
import QuartzCore


class UISubLayerFillView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        if var layer = self.layer.sublayers.first as? CAGradientLayer {
            layer.frame = self.bounds
        }
    }


}
