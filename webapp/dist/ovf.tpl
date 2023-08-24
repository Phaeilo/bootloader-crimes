<?xml version="1.0"?>
<Envelope ovf:version="2.0" xml:lang="en-US" xmlns="http://schemas.dmtf.org/ovf/envelope/2" xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/2" xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData" xmlns:vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:epasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_EthernetPortAllocationSettingData.xsd" xmlns:sasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_StorageAllocationSettingData.xsd">
  <References>
    <File ovf:id="file1" ovf:href="disk.vmdk"/>
  </References>
  <DiskSection>
    <Info>List of the virtual disks used in the package</Info>
    <Disk ovf:capacity="107374182400" ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"/>
  </DiskSection>
  <NetworkSection>
    <Info>Logical networks used in the package</Info>
    <Network ovf:name="NAT">
      <Description>Logical network used by this appliance.</Description>
    </Network>
  </NetworkSection>
  <VirtualSystem ovf:id="winvm">
    <Info>A virtual machine</Info>
    <ProductSection>
      <Info>Meta-information about the installed software</Info>
      <Product>The Product</Product>
      <Vendor>The Vendorr</Vendor>
      <Version>0.0.1337</Version>
      <ProductUrl>https://example.com/product-url</ProductUrl>
      <VendorUrl>https://example.com/vendor-url</VendorUrl>
    </ProductSection>
    <AnnotationSection>
      <Info>A human-readable annotation</Info>
      <Annotation>Hello World!</Annotation>
    </AnnotationSection>
    <EulaSection>
      <Info>License agreement for the virtual system</Info>
      <License>TODO</License>
    </EulaSection>
    <OperatingSystemSection ovf:id="102">
      <Info>The kind of installed guest operating system</Info>
      <Description>Other_64</Description>
    </OperatingSystemSection>
    <VirtualHardwareSection>
      <Info>Virtual hardware requirements for a virtual machine</Info>
      <System>
        <vssd:ElementName>Virtual Hardware Family</vssd:ElementName>
        <vssd:InstanceID>0</vssd:InstanceID>
        <vssd:VirtualSystemIdentifier>winvm</vssd:VirtualSystemIdentifier>
        <vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>
      </System>
      <Item>
        <rasd:Caption>${VM_CORES} virtual CPU</rasd:Caption>
        <rasd:Description>Number of virtual CPUs</rasd:Description>
        <rasd:InstanceID>1</rasd:InstanceID>
        <rasd:ResourceType>3</rasd:ResourceType>
        <rasd:VirtualQuantity>${VM_CORES}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:AllocationUnits>MegaBytes</rasd:AllocationUnits>
        <rasd:Caption>${VM_RAM} MB of memory</rasd:Caption>
        <rasd:Description>Memory Size</rasd:Description>
        <rasd:InstanceID>2</rasd:InstanceID>
        <rasd:ResourceType>4</rasd:ResourceType>
        <rasd:VirtualQuantity>${VM_RAM}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:Caption>ideController0</rasd:Caption>
        <rasd:Description>IDE Controller</rasd:Description>
        <rasd:InstanceID>3</rasd:InstanceID>
        <rasd:ResourceSubType>PIIX4</rasd:ResourceSubType>
        <rasd:ResourceType>5</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:Address>1</rasd:Address>
        <rasd:Caption>ideController1</rasd:Caption>
        <rasd:Description>IDE Controller</rasd:Description>
        <rasd:InstanceID>4</rasd:InstanceID>
        <rasd:ResourceSubType>PIIX4</rasd:ResourceSubType>
        <rasd:ResourceType>5</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:Caption>usb</rasd:Caption>
        <rasd:Description>USB Controller</rasd:Description>
        <rasd:InstanceID>5</rasd:InstanceID>
        <rasd:ResourceType>23</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>3</rasd:AddressOnParent>
        <rasd:AutomaticAllocation>false</rasd:AutomaticAllocation>
        <rasd:Caption>sound</rasd:Caption>
        <rasd:Description>Sound Card</rasd:Description>
        <rasd:InstanceID>6</rasd:InstanceID>
        <rasd:ResourceSubType>ensoniq1371</rasd:ResourceSubType>
        <rasd:ResourceType>35</rasd:ResourceType>
      </Item>
      <StorageItem>
        <sasd:AddressOnParent>0</sasd:AddressOnParent>
        <sasd:Caption>disk1</sasd:Caption>
        <sasd:Description>Disk Image</sasd:Description>
        <sasd:HostResource>/disk/vmdisk1</sasd:HostResource>
        <sasd:InstanceID>7</sasd:InstanceID>
        <sasd:Parent>3</sasd:Parent>
        <sasd:ResourceType>17</sasd:ResourceType>
      </StorageItem>
      <EthernetPortItem>
        <epasd:AutomaticAllocation>true</epasd:AutomaticAllocation>
        <epasd:Caption>Ethernet adapter on 'NAT'</epasd:Caption>
        <epasd:Connection>NAT</epasd:Connection>
        <epasd:InstanceID>8</epasd:InstanceID>
        <epasd:ResourceSubType>E1000</epasd:ResourceSubType>
        <epasd:ResourceType>10</epasd:ResourceType>
      </EthernetPortItem>
    </VirtualHardwareSection>
  </VirtualSystem>
</Envelope>
