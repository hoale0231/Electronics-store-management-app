import { Modal, Form, Col } from 'react-bootstrap'
import BootstrapTable from "react-bootstrap-table-next";
import { Component } from 'react';

export default class HotProduct extends Component {
    constructor(props) {
        super(props);
        this.state = {
            info: []
        }
        this.getInfo = this.getInfo.bind(this)
        this.getInfo()
    }

    getInfo() {
        fetch("/api/order/hotproduct")
      .then((response) => {
        if (response.ok) {
          return response.json()
        } else {
          response.text().then(text => { alert(text);})
        }
      })
      .then((data) => {console.log(data); this.setState({info: data})})
      .catch((error) => {
        console.error("Error fetching data: ", error);
      })
    }

    columns = [
        { dataField: "Product_Name", text: "Product Name"},
        { dataField: "Product_Type", text: "Product Type"},
        { dataField: "Product_Price", text: "Product Price"},
        { dataField: "Sold", text: "Sold"}
    ];

    render() {
        const {disableHotProduct} = this.props
        return (
            <div className="popup-background">
            <Modal.Dialog className="popup" size="lg">
                <Modal.Header closeButton onClick={() => {disableHotProduct()}}>
                <Modal.Title>Hot Product</Modal.Title>
                </Modal.Header>
                <Modal.Body className="body-popup">
                    <BootstrapTable keyField="id" data={this.state.info} columns={this.columns}/>
                </Modal.Body>
            </Modal.Dialog>
            </div>
        )
    }
}


function InputGroupCustom(props) {
  const { info, attr, attrName, required, handleInputChange, md, disable } = props
  return (
    <Form.Group as={Col} md={md}>
      <Form.Label>{attrName}</Form.Label>
      <Form.Control
        required={required}
        disabled={disable}
        name={attr}
        type="text"
        defaultValue={info[attr]}
        onChange={handleInputChange}
      />
      <Form.Control.Feedback type="invalid">
        Invalid {attr}
      </Form.Control.Feedback>
    </Form.Group>
  )
}