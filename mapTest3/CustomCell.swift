//
//  CustomCell.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/8/31.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {

    @IBOutlet weak var identifier: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var POIicon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
