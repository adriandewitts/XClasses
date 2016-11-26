//
//  UITable.swift
//  Beachcomber
//
//  Created by Adrian on 22/11/16.
//  Copyright © 2016 NACC. All rights reserved.
//

import UIKit
import Nuke

class XUITableViewController: UITableViewController, ViewModelDelegate
{
    var viewModel = ViewModel()
    var viewModelCollection = [ViewModel()]
    var numberOfSections = 1
    var reuseIdentifier = "Cell"

    override func viewDidLoad()
    {
        super.viewDidLoad()
        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection()
        self.clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        XUIFlowController.sharedInstance.viewModel = (sender as! XUITableViewCell).viewModel
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return viewModelCollection.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! XUITableViewCell
        cell.assignViewModelToView(viewModel: viewModelCollection[indexPath.item])

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
}

class XUITableViewCell: UITableViewCell, ViewModelDelegate
{
    var viewModel = ViewModel()

    @IBOutlet var thumb: UIImageView!
    @IBOutlet var title: UILabel!

    func assignViewModelToView(viewModel: ViewModel)
    {
        self.viewModel = viewModel
        let properties = viewModel.properties()

        if let imagePath = properties["image"]
        {
            thumb.contentMode = UIViewContentMode.scaleAspectFit
            Nuke.loadImage(with: imagePath.toURL(), into: thumb)
        }

        if let titleLabel = properties["title"]
        {
            title.text = titleLabel
        }
    }
}
