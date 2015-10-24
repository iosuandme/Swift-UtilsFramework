//
//  UITableViewThreeLabelCell.swift
//  ExamWinnerSwift
//
//  Created by 李招利 on 14/10/26.
//  Copyright (c) 2014年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class UITableViewThreeLabelCell: UITableViewCell {

    @IBOutlet weak var firstLabel:UILabel!
    @IBOutlet weak var secondLabel:UILabel!
    @IBOutlet weak var thridLabel:UILabel!

    func setAllLabelNumberOfLines(lines:Int) {
         firstLabel?.numberOfLines = lines
        secondLabel?.numberOfLines = lines
         thridLabel?.numberOfLines = lines
    }
    
    func setAllLabelLineBreakMode(mode:NSLineBreakMode) {
         firstLabel?.lineBreakMode = mode
        secondLabel?.lineBreakMode = mode
         thridLabel?.lineBreakMode = mode
    }

}
