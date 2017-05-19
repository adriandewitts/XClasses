//
//  UITable.swift
//  
//
//  Created by Adrian on 22/11/16.
//  Copyright © 2016 Adrian DeWitts. All rights reserved.
//

import UIKit
import Nuke

class XUITableViewController: UITableViewController, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate
    var viewModelCollection = [ViewModel() as ViewModelDelegate]
    var reuseIdentifier = "Cell"

    override func viewDidLoad()
    {
        super.viewDidLoad()
        viewModel = pullViewModel(viewModel: viewModel)
        viewModelCollection = viewModel.relatedCollection
        self.clearsSelectionOnViewWillAppear = false
        let vmTitle = viewModel.properties["title"]
        if vmTitle != "Placeholder"
        {
            self.title = vmTitle
        }
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
        return viewModelCollection.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return viewModelCollection[section].relatedCollection.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! XUITableViewCell
        cell.assignViewModelToView(viewModel: viewModelCollection[indexPath.section].relatedCollection[indexPath.item])

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell") as! XUITableViewCell
        headerCell.assignViewModelToView(viewModel: viewModelCollection[section])

        return headerCell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return false
    }
}

class XUITableViewCell: UITableViewCell, ViewModelManagerDelegate
{
    var viewModel = ViewModel() as ViewModelDelegate

    @IBOutlet var thumb: UIImageView!
    @IBOutlet var title: UILabel!

    func assignViewModelToView(viewModel: ViewModelDelegate)
    {
        self.viewModel = viewModel
        let properties = viewModel.properties

        if let imagePath = properties["image"]
        {
            if thumb != nil
            {
                thumb.contentMode = UIViewContentMode.scaleAspectFit
                //Nuke.loadImage(with: imagePath.toURL(), into: thumb)
            }
        }

        if let titleLabel = properties["title"]
        {
            if title != nil
            {
                title.text = titleLabel
            }
        }
    }
}
