//
//  DetailViewController.swift
//  mapTest3
//
//  Created by 蔡佳旅 on 2016/6/28.
//  Copyright © 2016年 蔡佳旅. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import Alamofire
import AlamofireImage
import AVFoundation
import AVKit
import AVFoundation

class DetailViewController: UIViewController, AVAudioPlayerDelegate {
    
    //@IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var AddressLabel: UILabel!
    @IBOutlet weak var DescriptionLabel: UILabel!

    var POIinfo: JSON = nil
    var audioPlayer = AVAudioPlayer()
    var audioIsPlaying: Bool = false
    var file_url : NSURL?
    private var ready = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        TitleLabel.text = POIinfo["POI_title"].stringValue
        AddressLabel.text = POIinfo["POI_address"].stringValue
        DescriptionLabel.text = POIinfo["POI_description"].stringValue
        
        let count = POIinfo["PICs"]["count"].stringValue
        let picArray = POIinfo["PICs"]["pic"].arrayValue
        let pic_count: Int = Int(count)!
        
        //find out width of master view controller
        let downNavigationVC = self.parentViewController as! UINavigationController
        let splitVC = downNavigationVC.parentViewController as! SplitViewController
        let topNavigationVC = splitVC.viewControllers[0] as! UINavigationController
        let masterVC = topNavigationVC.topViewController as!MasterViewController
        let masterVC_width = masterVC.view.bounds.size.width
        
        let mediaType = picArray[0]["media_fmt"].stringValue
        if mediaType == "1" {  //type 1 -> image
            
            scrollView.backgroundColor = UIColor.clearColor()
            scrollView.pagingEnabled = true
            scrollView.contentSize = CGSizeMake(CGFloat(pic_count) * (self.view.bounds.size.width-masterVC_width), self.view.bounds.size.height/2)
            
            //Setup each view sizeMPMoviePlayerController
            var viewSize = CGRectMake(0, 0, self.view.bounds.size.width-masterVC_width, self.view.bounds.size.height/2)
            
            for i in 0 ..< pic_count {
                let url = picArray[i]["url"].stringValue
                let downloadURL = NSURL(string: url)
                let data = NSData(contentsOfURL: downloadURL!)
                let image = UIImage(data: data!)!
                image.af_inflate()
                
                //Offset view size
                if i != 0 {
                    viewSize = CGRectOffset(viewSize, self.view.bounds.size.width-masterVC_width, 0)
                }
                
                //Setup and add images
                let imgView = UIImageView(frame: viewSize)
                imgView.image = image
                imgView.contentMode = .ScaleAspectFit
                
                scrollView.addSubview(imgView)
            }
        }
        else if mediaType == "2" {  //type 2 -> audio
            let url = picArray[0]["url"].stringValue
            let fileURL = NSURL(string: url)
            let soundData = NSData(contentsOfURL: fileURL!)
            
            do {
                self.audioPlayer = try AVAudioPlayer(data: soundData!)
                audioPlayer.prepareToPlay()
                audioPlayer.volume = 1.0
                audioPlayer.delegate = self
            } catch let error as NSError {
                print("\nError : \n"+error.localizedDescription)
            }
            
            let img = UIImage(named: "audio_icon.png")
            let button = UIButton(type: UIButtonType.System) as UIButton
            button.frame = CGRectMake(0, 0, self.view.bounds.size.width-masterVC_width, self.view.bounds.size.height/2)
            button.setImage(img, forState: .Normal)
            button.imageEdgeInsets = UIEdgeInsetsMake(20, 180, 20, 180)
            button.addTarget(self, action: #selector(DetailViewController.PlayAudio(_:)), forControlEvents: .TouchUpInside)
            
            scrollView.addSubview(button)
        }
        else if mediaType == "4" {  //type 4 -> video
            let url = picArray[0]["url"].stringValue
            self.file_url = NSURL(string: url)!
            
            let img = UIImage(named: "video_icon.png")
            let button = UIButton(type: UIButtonType.System) as UIButton
            button.frame = CGRectMake(0, 0, self.view.bounds.size.width-masterVC_width, self.view.bounds.size.height/2)
            button.setImage(img, forState: .Normal)
            button.imageEdgeInsets = UIEdgeInsetsMake(20, 180, 20, 180)
            button.addTarget(self, action: #selector(DetailViewController.PlayVideo(_:)), forControlEvents: .TouchUpInside)
            
            scrollView.addSubview(button)
        }
    }

    override func viewDidLayoutSubviews() {
        //scrollView.contentSize = CGSize(width: 600, height:292)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func PlayAudio(sender: AnyObject?) {
        if audioIsPlaying == false {
            audioPlayer.play()
            audioIsPlaying = true
        }
        else {
            audioPlayer.pause()
            audioIsPlaying = false
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        audioIsPlaying = false
    }
    
    // MARK : - Peform segue to AKPlayerController
    @IBAction func PlayVideo(sender: AnyObject?) {
        performSegueWithIdentifier("videoPlayer", sender: self.file_url)

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "videoPlayer" {
            if let destinationVC = segue.destinationViewController as? VideoPlayerViewController {
                destinationVC.fileURL = sender as! NSURL
            }
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: - Download images from URL

    

}
