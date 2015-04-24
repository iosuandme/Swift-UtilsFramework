//
//  TextViewCell.swift
//  ExamWinnerSwift
//
//  Created by CocoaController on 15/2/6.
//  Copyright (c) 2015年 Jintianyu Culture Communication Co., Ltd. All rights reserved.
//

import UIKit

class TextViewCell: UITableViewCell {

    @IBOutlet weak var AnswerTextView: UITextView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
