//
//  VideoPlayerViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/7/7.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoPlayerViewController: AVPlayerViewController {

    var fileURL: NSURL?
    var videoPlayer = AVPlayer()
    var playerLayer: AVPlayerLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blackColor()
        videoPlayer = AVPlayer(URL: fileURL!)
        self.player = videoPlayer
        self.showsPlaybackControls = true
        self.view.frame = CGRectMake(0, 0, self.view.bounds.width-320, self.view.bounds.height)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
